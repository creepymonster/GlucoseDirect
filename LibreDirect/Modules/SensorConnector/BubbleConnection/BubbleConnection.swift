//
//  BubbleConnection.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - BubbleConnection

class BubbleConnection: SensorBLEConnection {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<AppAction, AppError>) {
        AppLog.info("init")
        super.init(subject: subject, serviceUuid: CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"), restoreIdentifier: "libre-direct.bubble.restore-identifier")
    }

    // MARK: Internal

    override func resetBuffer() {
        rxBuffer = Data()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")

        guard peripheral.name?.lowercased().starts(with: "bubble") ?? false else {
            return
        }

        manager.stopScan()
        connect(peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                AppLog.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics([writeCharacteristicUuid, readCharacteristicUuid], for: service)
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
                    peripheral.setNotifyValue(true, for: characteristic)
                }

                if characteristic.uuid == writeCharacteristicUuid {
                    writeCharacteristic = characteristic
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        guard let writeCharacteristic = writeCharacteristic else {
            return
        }

        peripheral.writeValue(Data([0x00, 0x00, 0x01]), for: writeCharacteristic, type: .withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")

        guard let value = characteristic.value else {
            return
        }

        guard let firstByte = value.first, let bubbleResponseState = BubbleResponseType(rawValue: firstByte) else {
            return
        }

        AppLog.info("BubbleResponseState: \(bubbleResponseState)")

        switch bubbleResponseState {
        case .dataInfo:
            let hardwareMajor = value[value.count-2]
            let hardwareMinor = value[value.count-1]
            let hardware = Double("\(hardwareMajor).\(hardwareMinor)")
            let firmwareMajor = value[2]
            let firmwareMinor = value[3]
            let firmware = Double("\(firmwareMajor).\(firmwareMinor)")
            let battery = Int(value[4])

            let transmitter = Transmitter(name: peripheral.name ?? "Bubble", battery: battery, firmware: firmware, hardware: hardware)
            sendUpdate(transmitter: transmitter)

            if let writeCharacteristic = writeCharacteristic {
                if let firmware = firmware, firmware >= 2.6, false {
                    peripheral.writeValue(Data([0x08, 0x01, 0x00, 0x00, 0x00, 0x2b]), for: writeCharacteristic, type: .withResponse)
                } else {
                    peripheral.writeValue(Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x2b]), for: writeCharacteristic, type: .withResponse)
                }
            }

        case .decryptedDataPacket:
            rxBuffer.append(value.suffix(from: 4))

            if rxBuffer.count >= expectedBufferSize {
                AppLog.info("Completed DecryptedDataPacket")

                guard let uuid = uuid, let patchInfo = patchInfo else {
                    resetBuffer()
                    return
                }

                let type = sensor?.type ?? SensorType(patchInfo)
                guard type == .libre1 || type == .libre2EU || type == .libreUS14day else {
                    resetBuffer()
                    return
                }

                let fram = rxBuffer[..<expectedBufferSize]

                let sensor = Sensor(uuid: uuid, patchInfo: patchInfo, fram: fram)
                if self.sensor == nil || self.sensor?.serial != sensor.serial {
                    self.sensor = sensor
                    sendUpdate(sensor: sensor)
                }

                if sensor.age >= sensor.lifetime {
                    sendUpdate(age: sensor.age, state: .expired)

                } else if sensor.age > sensor.warmupTime {
                    sendUpdate(age: sensor.age, state: .ready)

                    let readings = SensorUtility.parseFRAM(calibration: sensor.factoryCalibration, pairingTimestamp: sensor.pairingTimestamp, fram: fram)
                    sendUpdate(trendReadings: readings.trend, historyReadings: readings.history)

                } else if sensor.age <= sensor.warmupTime {
                    sendUpdate(age: sensor.age, state: .starting)
                }

                resetBuffer()
            }

        case .dataPacket:
            rxBuffer.append(value.suffix(from: 4))

            if rxBuffer.count >= expectedBufferSize {
                AppLog.info("Completed DataPacket")

                guard let uuid = uuid, let patchInfo = patchInfo else {
                    resetBuffer()
                    return
                }

                let type = sensor?.type ?? SensorType(patchInfo)
                guard type == .libre1 || type == .libre2EU || type == .libreUS14day else {
                    resetBuffer()
                    return
                }

                let fram = type == .libre1
                    ? rxBuffer[..<expectedBufferSize]
                    : SensorUtility.decryptFRAM(uuid: uuid, patchInfo: patchInfo, fram: rxBuffer[..<expectedBufferSize])

                if let fram = fram {
                    let sensor = Sensor(uuid: uuid, patchInfo: patchInfo, fram: fram)
                    if self.sensor == nil || self.sensor?.serial != sensor.serial {
                        self.sensor = sensor
                        sendUpdate(sensor: sensor)
                    }

                    if sensor.age >= sensor.lifetime {
                        sendUpdate(age: sensor.age, state: .expired)

                    } else if sensor.age > sensor.warmupTime {
                        sendUpdate(age: sensor.age, state: .ready)

                        let readings = SensorUtility.parseFRAM(calibration: sensor.factoryCalibration, pairingTimestamp: sensor.pairingTimestamp, fram: fram)
                        sendUpdate(trendReadings: readings.trend, historyReadings: readings.history)

                    } else if sensor.age <= sensor.warmupTime {
                        sendUpdate(age: sensor.age, state: .starting)
                    }
                }

                resetBuffer()
            }

        case .noSensor:
            sendMissedUpdate()
            resetBuffer()

        case .serialNumber:
            guard value.count >= 10 else {
                return
            }

            uuid = value.subdata(in: 2 ..< 10)
            resetBuffer()

        case .patchInfo:
            patchInfo = value.subdata(in: 5 ..< 11)
        }
    }

    // MARK: Private

    private let expectedBufferSize = 344

    private let writeCharacteristicUuid = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private let readCharacteristicUuid = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?

    private var uuid: Data?
    private var patchInfo: Data?
    private var hardware: Double?
    private var firmware: Double?

    private var rxBuffer = Data()
}

// MARK: - BubbleResponseType

private enum BubbleResponseType: UInt8 {
    case dataInfo = 128 // = wakeUp + device info
    case dataPacket = 130
    case decryptedDataPacket = 0x88
    case noSensor = 191
    case patchInfo = 193 // 0xC1
    case serialNumber = 192
}
