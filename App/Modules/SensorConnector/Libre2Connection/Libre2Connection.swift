//
//  Libre2Connection.swift
//  GlucoseDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - Libre2Connection

final class Libre2Connection: SensorBLEConnectionBase, IsSensor {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<AppAction, AppError>) {
        DirectLog.info("init")

        super.init(subject: subject, serviceUUID: CBUUID(string: "FDE3"))
    }

    // MARK: Internal

    override var peripheralName: String {
        "abbott"
    }

    override func pairConnection() {
        DirectLog.info("PairSensor")

        UserDefaults.standard.libre2UnlockCount = 0

        sendUpdate(connectionState: .pairing)
        pairingService?.readSensor()
    }

    override func resetBuffer() {
        DirectLog.info("ResetBuffer")

        firstBuffer = Data()
        secondBuffer = Data()
        thirdBuffer = Data()
    }

    override func checkRetrievedPeripheral(peripheral: CBPeripheral) -> Bool {
        if let sensorSerial = sensor?.serial {
            return peripheral.name == "ABBOTT\(sensorSerial)"
        }

        return false
    }

    func unlock() -> Data? {
        DirectLog.info("Unlock, count: \(UserDefaults.standard.libre2UnlockCount)")

        if sensor == nil {
            return nil
        }

        let unlockCount = UserDefaults.standard.libre2UnlockCount + 1
        let unlockPayload = SensorUtility.streamingUnlockPayload(uuid: sensor!.uuid, patchInfo: sensor!.patchInfo, enableTime: 42, unlockCount: UInt16(unlockCount))

        UserDefaults.standard.libre2UnlockCount = unlockCount

        DirectLog.info("Unlock done, count: \(UserDefaults.standard.libre2UnlockCount)")

        return Data(unlockPayload)
    }

    override func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        DirectLog.info("Found peripheral: \(peripheral.name ?? "-")")

        guard manager != nil else {
            DirectLog.error("Guard: manager is nil")
            return
        }

        guard let sensor = sensor, let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }

        DirectLog.info("Sensor: \(sensor)")
        DirectLog.info("ManufacturerData: \(manufacturerData)")

        if manufacturerData.count == 8 {
            var foundUUID = manufacturerData.subdata(in: 2 ..< 8)
            foundUUID.append(contentsOf: [0x07, 0xe0])

            let result = foundUUID == sensor.uuid && peripheral.name?.lowercased().starts(with: peripheralName) ?? false
            if result {
                manager.stopScan()
                connect(peripheral)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        DirectLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                DirectLog.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics([readCharacteristicUUID, writeCharacteristicUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        DirectLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                DirectLog.info("Characteristic Uuid: \(characteristic.uuid.description)")

                if characteristic.uuid == readCharacteristicUUID {
                    readCharacteristic = characteristic
                }

                if characteristic.uuid == writeCharacteristicUUID {
                    writeCharacteristic = characteristic

                    if peripheralType != .connectedPeripheral, let unlock = unlock() {
                        peripheral.writeValue(unlock, for: characteristic, type: .withResponse)
                    }
                }
            }
        }

        if let readCharacteristic = readCharacteristic {
            peripheral.setNotifyValue(true, for: readCharacteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        DirectLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        guard let value = characteristic.value else {
            return
        }

        if value.count == 20 {
            firstBuffer = value
        } else if value.count == 18 {
            secondBuffer = value
        } else if value.count == 8 {
            thirdBuffer = value
        }

        DirectLog.info("Value: \(value.count)")
        DirectLog.info("First buffer: \(firstBuffer.count)")
        DirectLog.info("Second buffer: \(secondBuffer.count)")
        DirectLog.info("Third buffer: \(thirdBuffer.count)")

        if !firstBuffer.isEmpty, !secondBuffer.isEmpty, !thirdBuffer.isEmpty {
            let rxBuffer = firstBuffer + secondBuffer + thirdBuffer

            if let sensor = sensor {
                do {
                    let decryptedBLE = Data(try SensorUtility.decryptBLE(uuid: sensor.uuid, data: rxBuffer))
                    let parsedBLE = SensorUtility.parseBLE(calibration: sensor.factoryCalibration, data: decryptedBLE)

                    if (parsedBLE.age + 30) >= sensor.lifetime {
                        sendUpdate(age: parsedBLE.age, state: .expired)
                        lastReadings = []

                    } else if let nextReading = parsedBLE.trend.last, parsedBLE.age > sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .ready)

                        if let lastReading = lastReadings.last, (nextReading.timestamp.timeIntervalSince1970 - lastReading.timestamp.timeIntervalSince1970) > 90 {
                            DirectLog.info("Time difference of the read values too large: \(nextReading.timestamp.timeIntervalSince1970 - lastReading.timestamp.timeIntervalSince1970)")

                            lastReadings = [nextReading]
                        } else {
                            DirectLog.info("Time difference of the read values is OK or this is the first read")

                            var lastReadings = self.lastReadings + [nextReading]

                            let overLimit = lastReadings.count - 5
                            if overLimit > 0 {
                                lastReadings = Array(lastReadings.dropFirst(overLimit))
                            }

                            self.lastReadings = lastReadings
                        }
                    } else if parsedBLE.age <= sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .starting)
                        lastReadings = []
                    }
                } catch {
                    DirectLog.error("Cannot process BLE data: \(error.localizedDescription)")
                }

                let intervalSeconds = sensorInterval * 60 - 45
                if sensorInterval == 1 || lastUpdate == nil || lastUpdate! + Double(intervalSeconds) <= Date() {
                    lastUpdate = Date()                   
                    sendUpdate(sensorSerial: sensor.serial ?? "", readings: lastReadings)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                self.resetBuffer()
            }
        }
    }

    // MARK: Private

    private let writeCharacteristicUUID = CBUUID(string: "F001")
    private let readCharacteristicUUID = CBUUID(string: "F002")

    private var writeCharacteristic: CBCharacteristic?
    private var readCharacteristic: CBCharacteristic?

    private lazy var pairingService: Libre2Pairing? = {
        if let subject = subject {
            return Libre2Pairing(subject: subject)
        }

        return nil
    }()

    private var firstBuffer = Data()
    private var secondBuffer = Data()
    private var thirdBuffer = Data()

    private var lastUpdate: Date?
    private var lastReadings: [SensorReading] = []
}

private extension UserDefaults {
    enum Keys: String {
        case libre2UnlockCount = "libre-direct.libre2.unlock-count"
    }

    var libre2UnlockCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.libre2UnlockCount.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.libre2UnlockCount.rawValue)
        }
    }
}
