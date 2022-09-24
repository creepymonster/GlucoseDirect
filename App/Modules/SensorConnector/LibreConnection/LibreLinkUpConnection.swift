//
//  LibreLinkUpConnection.swift
//  GlucoseDirectApp
//

import Combine
import CoreBluetooth
import Foundation

class LibreLinkUpConnection: SensorBluetoothConnection, IsSensor {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<DirectAction, DirectError>) {
        super.init(subject: subject, serviceUUID: CBUUID(string: "089810CC-EF89-11E9-81B4-2A2AE2DBCCE4"))
    }

    // MARK: Internal

    override var peripheralName: String {
        ""
    }

    override func resetBuffer() {
    }

    override func checkRetrievedPeripheral(peripheral: CBPeripheral) -> Bool {
        return true
    }

    override func pairConnection() {
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

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        DirectLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                DirectLog.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        DirectLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                DirectLog.info("Characteristic Uuid: \(characteristic.uuid.description)")

                if characteristic.uuid == oneMinuteReadingUUID {
                    oneMinuteReadingCharacteristic = characteristic
                }
            }
        }

        if let characteristic = oneMinuteReadingCharacteristic {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        DirectLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        guard let value = characteristic.value else {
            return
        }

        DirectLog.info("Peripheral: \(value.hex)")
    }

    // MARK: Private

    private let oneMinuteReadingUUID = CBUUID(string: "0898177A-EF89-11E9-81B4-2A2AE2DBCCE4")
    private var oneMinuteReadingCharacteristic: CBCharacteristic?
}
