//
//  Bubble.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 30.09.21. 
//  Used code from dabear, https://github.com/dabear/LibreTransmitter/blob/main/Bluetooth/Transmitter/BubbleTransmitter.swift
//

import Foundation
import Combine
import CoreBluetooth

public func bubbleMiddelware() -> Middleware<AppState, AppAction> {
    return bubbleMiddelware(service: BubbleService())
}

fileprivate func bubbleMiddelware(service: BubbleService) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        let completionHandler: DeviceConnectionHandler = { (update) -> Void in
            let dispatch = store.dispatch
            var action: AppAction? = nil

            if let connectionUpdate = update as? DeviceConnectionUpdate {
                action = .setSensorConnection(connectionState: connectionUpdate.connectionState)

            } else if let readingUpdate = update as? DeviceGlucoseUpdate {
                if let glucose = readingUpdate.glucose {
                    action = .setSensorReading(glucose: glucose)
                } else {
                    action = .setSensorMissedReadings
                }

            } else if let ageUpdate = update as? DeviceAgeUpdate {
                action = .setSensorAge(sensorAge: ageUpdate.sensorAge)

            } else if let errorUpdate = update as? DeviceErrorUpdate {
                action = .setSensorError(errorMessage: errorUpdate.errorMessage, errorTimestamp: errorUpdate.errorTimestamp)

            } else if let sensorUpdate = update as? DeviceSensorUpdate {
                action = .setSensor(value: sensorUpdate.sensor)

            }

            if let action = action {
                DispatchQueue.main.async {
                    dispatch(action)
                }
            }
        }

        switch action {
        case .pairSensor:
            service.pairSensor(completionHandler: completionHandler)

        case .connectSensor:
            guard let sensor = store.state.sensor else {
                break
            }

            service.connectSensor(sensor: sensor, completionHandler: completionHandler)

        case .disconnectSensor:
            service.disconnectSensor()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

public enum BubbleResponseType: UInt8 {
    case dataPacket = 130
    case bubbleInfo = 128 // = wakeUp + device info
    case noSensor = 191
    case serialNumber = 192
    case patchInfo = 193 //0xC1
    case decryptedDataPacket = 136 // 0x88
}

class BubbleService: DeviceService {
    let expectedBufferSize = 352

    var writeCharacteristicUuid: CBUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    var readCharacteristicUuid: CBUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    var writeCharacteristic: CBCharacteristic?
    var readCharacteristic: CBCharacteristic?

    var uuid: Data? = nil
    var patchInfo: Data? = nil

    init() {
        super.init(serviceUuid: [CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")])
    }

    func pairSensor(completionHandler: @escaping DeviceConnectionHandler) {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("PairSensor")

        connectionCompletionHandler = completionHandler

        managerQueue.async {
            self.find()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        guard peripheral.name?.lowercased().starts(with: "bubble") ?? false else {
            return
        }

        connect(peripheral)

        guard let data = advertisementData["kCBAdvDataManufacturerData"] as? Data else {
            return
        }

        var mac = ""
        for i in 0 ..< 6 {
            mac += data.subdata(in: (7 - i)..<(8 - i)).hex.uppercased()
            if i != 5 {
                mac += ":"
            }
        }

        guard data.count >= 12 else {
            return
        }

        let fSub1 = Data(repeating: data[8], count: 1)
        let fSub2 = Data(repeating: data[9], count: 1)
        let firmware = Float("\(fSub1.hex).\(fSub2.hex)")?.description

        let hSub1 = Data(repeating: data[10], count: 1)
        let hSub2 = Data(repeating: data[11], count: 1)

        let hardware = Float("\(hSub1.hex).\(hSub2.hex)")?.description

        guard let hardware = hardware, let firmware = firmware else {
            return
        }

        Log.info("Firmware: \(firmware)")
        Log.info("Hardware: \(hardware)")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(connectionState: .connected)
        peripheral.discoverServices(serviceUuid)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(connectionState: .disconnected)
        sendUpdate(error: error)

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(connectionState: .disconnected)
        sendUpdate(error: error)

        guard stayConnected else {
            return
        }

        connect()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                Log.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics([writeCharacteristicUuid, readCharacteristicUuid], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                Log.info("Characteristic Uuid: \(characteristic.uuid.description)")

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
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        guard let writeCharacteristic = writeCharacteristic else {
            return
        }

        peripheral.writeValue(Data([0x00, 0x00, 0x01]), for: writeCharacteristic, type: .withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        guard let value = characteristic.value else {
            return
        }

        guard let firstByte = value.first, let bubbleResponseState = BubbleResponseType(rawValue: firstByte) else {
            return
        }

        Log.info("BubbleResponseState: \(bubbleResponseState)")

        switch bubbleResponseState {
        case .bubbleInfo:
            let battery = Int(value[4])
            Log.info("Battery: \(battery)")

            if let writeCharacteristic = writeCharacteristic {
                peripheral.writeValue(Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x2B]), for: writeCharacteristic, type: .withResponse)
            }

        case .dataPacket, .decryptedDataPacket:
            rxBuffer.append(value.suffix(from: 4))

            if rxBuffer.count >= expectedBufferSize {
                Log.info("Completed DataPacket")

                guard let uuid = uuid, let patchInfo = patchInfo else {
                    resetBuffer()

                    return
                }

                self.sensor = Sensor(uuid: uuid, patchInfo: patchInfo, fram: rxBuffer)

                Log.info(sensor!.description)
                sendUpdate(sensor: sensor!)
            }

        case .noSensor:
            resetBuffer()

        case .serialNumber:
            guard value.count >= 10 else {
                return
            }

            resetBuffer()

            uuid = value.subdata(in: 2..<10)

            if let uuid = uuid {
                Log.info("Uuid: \(uuid.hex)")
            }

            //for historical reasons
            rxBuffer.append(value.subdata(in: 2..<10))

        case .patchInfo:
            patchInfo = value.subdata(in: 5 ..< 11)

            if let patchInfo = patchInfo {
                Log.info("PatchInfo: \(patchInfo.hex)")
            }
        }
    }
}
