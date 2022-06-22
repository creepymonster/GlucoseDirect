//
//  LibreLinkConnection.swift
//  GlucoseDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - LibreLinkConnection

class LibreLinkConnection: SensorBLEConnectionBase, IsSensor {
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

    override func find() {
        DirectLog.info("Find")

        guard manager != nil else {
            DirectLog.error("Guard: manager is nil")
            return
        }

        guard manager.state == .poweredOn else {
            DirectLog.error("Guard: manager.state \(manager.state.rawValue) is not .poweredOn")
            return
        }

        if let connectedPeripheral = manager.retrieveConnectedPeripherals(withServices: [serviceUUID]).first,
           checkRetrievedPeripheral(peripheral: connectedPeripheral)
        {
            DirectLog.info("Connect from retrievePeripherals")

            peripheralType = .connectedPeripheral
            connect(connectedPeripheral)

        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                self.find()
            }
        }
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
                }
            }
        }

        if let readCharacteristic = readCharacteristic {
            peripheral.setNotifyValue(true, for: readCharacteristic)
            lastUpdate = nil
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
                    let decryptedBLE = Data(try Libre2EUtility.decryptBLE(uuid: sensor.uuid, data: rxBuffer))
                    let parsedBLE = Libre2EUtility.parseBLE(calibration: sensor.factoryCalibration, data: decryptedBLE)

                    if (parsedBLE.age + 30) >= sensor.lifetime {
                        sendUpdate(age: parsedBLE.age, state: .expired)

                    } else if parsedBLE.age > sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .ready)

                        let intervalSeconds = Double(sensorInterval * 60 - 30)
                        if sensorInterval == 1 || lastUpdate == nil || lastUpdate! + intervalSeconds <= Date() {
                            lastUpdate = Date()
                            sendUpdate(sensorSerial: sensor.serial ?? "", readings: parsedBLE.history + parsedBLE.trend)
                        }
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

    private lazy var pairingService: LibreLinkPairing? = {
        if let subject = subject {
            return LibreLinkPairing(subject: subject)
        }

        return nil
    }()

    private var firstBuffer = Data()
    private var secondBuffer = Data()
    private var thirdBuffer = Data()

    private var lastUpdate: Date?
}
