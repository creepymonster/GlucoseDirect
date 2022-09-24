//
//  Libre2Connection.swift
//  GlucoseDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - Libre2Connection

class Libre2Connection: SensorBluetoothConnection, IsSensor {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<DirectAction, DirectError>) {
        super.init(subject: subject, serviceUUID: CBUUID(string: "FDE3"))
    }

    // MARK: Internal

    override var peripheralName: String {
        "abbott"
    }

    override func pairConnection() {
        UserDefaults.standard.libreUnlockCount = 0
    }

    override func resetBuffer() {
        DirectLog.info("ResetBuffer")

        firstBuffer = Data()
        secondBuffer = Data()
        thirdBuffer = Data()
    }

    override func checkRetrievedPeripheral(peripheral: CBPeripheral) -> Bool {
        if let sensorSerial = sensor?.serial {
            return peripheral.name?.lowercased() == "\(peripheralName)\(sensorSerial)"
        }

        return false
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

            if foundUUID == sensor.uuid {
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

            if let sensor = sensor, let factoryCalibration = sensor.factoryCalibration {
                do {
                    let decryptedBLE = Data(try Libre2EUtility.decryptBLE(uuid: sensor.uuid, data: rxBuffer))
                    let parsedBLE = Libre2EUtility.parseBLE(calibration: factoryCalibration, data: decryptedBLE)

                    if parsedBLE.age >= sensor.lifetime {
                        sendUpdate(age: parsedBLE.age, state: .expired)

                    } else if parsedBLE.age > sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .ready)
                        sendUpdate(sensorSerial: sensor.serial ?? "", readings: parsedBLE.history + parsedBLE.trend)

                    } else if parsedBLE.age <= sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .starting)
                    }
                } catch {
                    DirectLog.error("Cannot process BLE data: \(error.localizedDescription)")
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

    private var firstBuffer = Data()
    private var secondBuffer = Data()
    private var thirdBuffer = Data()

    private func unlock() -> Data? {
        DirectLog.info("Unlock, count: \(UserDefaults.standard.libreUnlockCount)")

        if sensor == nil {
            return nil
        }

        let unlockCount = UserDefaults.standard.libreUnlockCount + 1
        let unlockPayload = Libre2EUtility.streamingUnlockPayload(uuid: sensor!.uuid, patchInfo: sensor!.patchInfo, enableTime: 42, unlockCount: UInt16(unlockCount))

        UserDefaults.standard.libreUnlockCount = unlockCount

        return Data(unlockPayload)
    }
}

private extension UserDefaults {
    private enum Keys: String {
        case libreUnlockCount = "libre-direct.libre2.unlock-count"
    }

    var libreUnlockCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.libreUnlockCount.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.libreUnlockCount.rawValue)
        }
    }
}
