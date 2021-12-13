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

    init() {
        AppLog.info("init")
        super.init(serviceUuid: CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"), restoreIdentifier: "libre-direct.bubble.restore-identifier")
    }

    // MARK: Internal

    let expectedBufferSize = 344

    let writeCharacteristicUuid = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    let readCharacteristicUuid = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    var readCharacteristic: CBCharacteristic?
    var writeCharacteristic: CBCharacteristic?

    var uuid: Data?
    var patchInfo: Data?
    var hardware: Double?
    var firmware: Double?

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

            let transmitter = Transmitter(name: "Bubble", battery: battery, firmware: firmware, hardware: hardware)
            sendUpdate(transmitter: transmitter)

            if let writeCharacteristic = writeCharacteristic {
                peripheral.writeValue(Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x2b]), for: writeCharacteristic, type: .withResponse)
            }

        case .dataPacket:
            rxBuffer.append(value.suffix(from: 4))

            if rxBuffer.count >= expectedBufferSize {
                AppLog.info("Completed DataPacket")

                guard let uuid = uuid, let patchInfo = patchInfo else {
                    resetBuffer()

                    return
                }

                let family = sensor?.family ?? SensorFamily(patchInfo)
                let fram = family == .libre1
                    ? rxBuffer[..<344]
                    : SensorUtility.decryptFRAM(uuid: uuid, patchInfo: patchInfo, fram: rxBuffer[..<344])

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
}

// MARK: - BubbleResponseType

private enum BubbleResponseType: UInt8 {
    case dataPacket = 130
    case dataInfo = 128 // = wakeUp + device info
    case noSensor = 191
    case serialNumber = 192
    case patchInfo = 193 // 0xC1
}
