//
//  Libre2Connection.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - Libre2Connection

final class Libre2Connection: SensorBLEConnection {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<AppAction, AppError>) {
        AppLog.info("init")

        pairingService = Libre2Pairing(subject: subject)
        super.init(subject: subject, serviceUuid: CBUUID(string: "FDE3"), restoreIdentifier: "libre-direct.libre2.restore-identifier")
    }

    // MARK: Internal

    override func pairSensor() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        AppLog.info("PairSensor")

        UserDefaults.standard.peripheralUuid = nil
        UserDefaults.standard.libre2UnlockCount = 0

        sendUpdate(connectionState: .pairing)
        pairingService.pairSensor()
    }

    override func resetBuffer() {
        firstBuffer = Data()
        secondBuffer = Data()
        thirdBuffer = Data()
    }

    func unlock() -> Data? {
        dispatchPrecondition(condition: .onQueue(managerQueue))
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

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")

        guard let sensor = sensor, let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }

        AppLog.info("Sensor: \(sensor)")
        AppLog.info("ManufacturerData: \(manufacturerData)")

        if manufacturerData.count == 8 {
            var foundUUID = manufacturerData.subdata(in: 2 ..< 8)
            foundUUID.append(contentsOf: [0x07, 0xe0])

            let result = foundUUID == sensor.uuid && peripheral.name?.lowercased().starts(with: "abbott") ?? false
            if result {
                manager.stopScan()
                connect(peripheral)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                AppLog.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics([readCharacteristicUuid, writeCharacteristicUuid], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                AppLog.info("Characteristic Uuid: \(characteristic.uuid.description)")

                if characteristic.uuid == readCharacteristicUuid {
                    readCharacteristic = characteristic
                }

                if characteristic.uuid == writeCharacteristicUuid {
                    writeCharacteristic = characteristic

                    if let unlock = unlock() {
                        peripheral.writeValue(unlock, for: characteristic, type: .withResponse)
                    }
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if characteristic.uuid == writeCharacteristicUuid {
            peripheral.setNotifyValue(true, for: readCharacteristic!)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
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

            if let sensor = sensor {
                do {
                    let decryptedBLE = Data(try SensorUtility.decryptBLE(uuid: sensor.uuid, data: rxBuffer))
                    let parsedBLE = SensorUtility.parseBLE(calibration: sensor.factoryCalibration, data: decryptedBLE)

                    if parsedBLE.age >= sensor.lifetime {
                        sendUpdate(age: parsedBLE.age, state: .expired)

                    } else if parsedBLE.age > sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .ready)
                        sendUpdate(trendReadings: parsedBLE.trend, historyReadings: parsedBLE.history)

                    } else if parsedBLE.age <= sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .starting)
                    }
                } catch {
                    AppLog.error("Cannot process BLE data: \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                self.resetBuffer()
            }
        }
    }

    // MARK: Private

    private let writeCharacteristicUuid = CBUUID(string: "F001")
    private let readCharacteristicUuid = CBUUID(string: "F002")

    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?

    private let pairingService: Libre2Pairing

    private var firstBuffer = Data()
    private var secondBuffer = Data()
    private var thirdBuffer = Data()
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
