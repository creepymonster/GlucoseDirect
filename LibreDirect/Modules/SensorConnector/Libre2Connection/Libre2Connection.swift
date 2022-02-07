//
//  Libre2Connection.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - Libre2Connection

final class Libre2Connection: SensorBLEConnectionBase, IsSensor {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<AppAction, AppError>) {
        AppLog.info("init")

        super.init(subject: subject, serviceUUID: CBUUID(string: "FDE3"))
    }

    // MARK: Internal

    override var peripheralName: String {
        "abbott"
    }

    override func pairSensor() {
        AppLog.info("PairSensor")

        UserDefaults.standard.libre2UnlockCount = 0

        sendUpdate(connectionState: .pairing)
        pairingService?.readSensor()
    }

    override func resetBuffer() {
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
        AppLog.info("Unlock, count: \(UserDefaults.standard.libre2UnlockCount)")

        if sensor == nil {
            return nil
        }

        let unlockCount = UserDefaults.standard.libre2UnlockCount + 1
        let unlockPayload = SensorUtility.streamingUnlockPayload(uuid: sensor!.uuid, patchInfo: sensor!.patchInfo, enableTime: 42, unlockCount: UInt16(unlockCount))

        UserDefaults.standard.libre2UnlockCount = unlockCount

        AppLog.info("Unlock done, count: \(UserDefaults.standard.libre2UnlockCount)")

        return Data(unlockPayload)
    }

    override func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        AppLog.info("Found peripheral: \(peripheral.name ?? "-")")
        
        guard manager != nil else {
            AppLog.error("Guard: manager is nil")
            return
        }

        guard let sensor = sensor, let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }

        AppLog.info("Sensor: \(sensor)")
        AppLog.info("ManufacturerData: \(manufacturerData)")

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
        AppLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                AppLog.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics([readCharacteristicUUID, writeCharacteristicUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        AppLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                AppLog.info("Characteristic Uuid: \(characteristic.uuid.description)")

                if characteristic.uuid == readCharacteristicUUID {
                    readCharacteristic = characteristic
                }

                if characteristic.uuid == writeCharacteristicUUID {
                    writeCharacteristic = characteristic

                    if let unlock = unlock() {
                        peripheral.writeValue(unlock, for: characteristic, type: .withResponse)
                    }
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        AppLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        AppLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if characteristic.uuid == writeCharacteristicUUID {
            peripheral.setNotifyValue(true, for: readCharacteristic!)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        AppLog.info("Peripheral: \(peripheral)")

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

        AppLog.info("Value: \(value.count)")
        AppLog.info("First buffer: \(firstBuffer.count)")
        AppLog.info("Second buffer: \(secondBuffer.count)")
        AppLog.info("Third buffer: \(thirdBuffer.count)")

        if !firstBuffer.isEmpty, !secondBuffer.isEmpty, !thirdBuffer.isEmpty {
            let rxBuffer = firstBuffer + secondBuffer + thirdBuffer

            let intervalSeconds = sensorInterval * 60 - 45
            guard sensorInterval == 1 || lastTimestamp == nil || lastTimestamp! + Double(intervalSeconds) <= Date() else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    self.resetBuffer()
                }

                return
            }

            lastTimestamp = Date()

            if let sensor = sensor {
                do {
                    let decryptedBLE = Data(try SensorUtility.decryptBLE(uuid: sensor.uuid, data: rxBuffer))
                    let parsedBLE = SensorUtility.parseBLE(calibration: sensor.factoryCalibration, data: decryptedBLE)

                    if (parsedBLE.age + 15) >= sensor.lifetime {
                        sendUpdate(age: parsedBLE.age, state: .expired)

                    } else if parsedBLE.age > sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .ready)
                        sendUpdate(sensorSerial: sensor.serial ?? "", trendReadings: parsedBLE.trend, historyReadings: parsedBLE.history)

                    } else if parsedBLE.age <= sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .starting)
                    }
                } catch {
                    AppLog.error("Cannot process BLE data: \(error.localizedDescription)")
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

    private var lastTimestamp: Date?
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
