//
//  SensorConnection.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine
import CoreBluetooth

@available(iOS 15.0, *)
class Libre2Service: DeviceService {
    let expectedBufferSize = 46

    var writeCharacteristicUuid: CBUUID = CBUUID(string: "F001")
    var readCharacteristicUuid: CBUUID = CBUUID(string: "F002")

    var readCharacteristic: CBCharacteristic?
    var writeCharacteristic: CBCharacteristic?

    init() {
        super.init(serviceUuid: [CBUUID(string: "FDE3")])
    }

    //func pairSensor(completionHandler: @escaping DeviceConnectionHandler) {
    func pairSensor() async -> Sensor? {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("PairSensor")

        //self.completionHandler = completionHandler

        //Task {
        let pairingService = Libre2Pairing()
        let pairedSensor = await pairingService.pairSensor()

        //if let pairedSensor = pairedSensor {
        //  DispatchQueue.main.async {
        //      UserDefaults.standard.libre2UnlockCount = 0
        //      self.completionHandler?(DeviceServiceSensorUpdate(sensor: pairedSensor))
        //  }
        //}

        UserDefaults.standard.libre2UnlockCount = 0
        return pairedSensor
        //}
    }

    func connectSensor(sensor: Sensor, completionHandler: @escaping DeviceConnectionHandler) {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("ConnectSensor: \(sensor)")

        self.completionHandler = completionHandler
        self.sensor = sensor

        managerQueue.async {
            self.find()
        }
    }

    func disconnectSensor() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("DisconnectSensor")

        self.sensor = nil
        self.lastGlucose = nil

        managerQueue.sync {
            self.disconnect()
        }
    }

    func unlock() -> Data? {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Unlock")

        if sensor == nil {
            return nil
        }

        UserDefaults.standard.libre2UnlockCount = UserDefaults.standard.libre2UnlockCount + 1

        let unlockPayload = Libre2.streamingUnlockPayload(sensorUID: sensor!.uuid, info: sensor!.patchInfo, enableTime: 42, unlockCount: UInt16(UserDefaults.standard.libre2UnlockCount))
        return Data(unlockPayload)
    }

    // MARK: - CBCentralManagerDelegate
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        guard let sensor = sensor, let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }

        Log.info("Sensor: \(sensor)")
        Log.info("ManufacturerData: \(manufacturerData)")

        if manufacturerData.count == 8 {
            var foundUUID = manufacturerData.subdata(in: 2..<8)
            foundUUID.append(contentsOf: [0x07, 0xe0])

            let result = foundUUID == sensor.uuid && peripheral.name?.lowercased().starts(with: "abbott") ?? false
            if result {
                manager.stopScan()
                connect(peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(connectionState: .connected)

        peripheral.discoverServices(serviceUuid)
    }

    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                Log.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics([readCharacteristicUuid, writeCharacteristicUuid], for: service)
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
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if characteristic.uuid == writeCharacteristicUuid {
            peripheral.setNotifyValue(true, for: readCharacteristic!)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        guard let value = characteristic.value else {
            return
        }

        rxBuffer.append(value)

        if rxBuffer.count == expectedBufferSize {
            if let sensor = sensor {
                do {
                    let decryptedBLE = Data(try Libre2.decryptBLE(sensorUID: sensor.uuid, data: rxBuffer))
                    let sensorUpdate = Libre2.parseBLEData(decryptedBLE, calibration: sensor.calibration)

                    sendUpdate(sensorAge: sensorUpdate.age)

                    if let newestGlucose = sensorUpdate.trend.last {
                        sendUpdate(glucose: newestGlucose)
                    } else {
                        sendEmptyGlucoseUpdate()
                    }

                    resetBuffer()
                } catch {
                    resetBuffer()
                }
            }
        }
    }
}

// MARK: - fileprivate
fileprivate extension UserDefaults {
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
