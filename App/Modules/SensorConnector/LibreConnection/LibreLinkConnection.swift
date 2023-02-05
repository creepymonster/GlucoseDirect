//
//  LibreLinkConnection.swift
//  GlucoseDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - LibreLinkConnection

class LibreLinkConnection: Libre2Connection {
    // MARK: Internal

    override func pairConnection() {
        DirectLog.info("PairSensor")

        Task {
            sendUpdate(connectionState: .pairing)

            do {
                let result = try await pairingService.readSensor(enableStreaming: false)

                sendUpdate(connectionState: .disconnected)
                
                guard result.sensor.type != .libre3 else {
                    return
                }
                
                sendUpdate(sensor: result.sensor)
                sendUpdate(isPaired: result.isPaired)

                if result.sensor.age >= result.sensor.lifetime {
                    sendUpdate(age: result.sensor.age, state: .expired)

                } else if result.sensor.age > result.sensor.warmupTime {
                    sendUpdate(age: result.sensor.age, state: result.sensor.state)
                    sendUpdate(readings: result.readings)

                } else if result.sensor.age <= result.sensor.warmupTime {
                    sendUpdate(age: result.sensor.age, state: .starting)
                }
            } catch {
                DirectLog.error("\(error)")

                sendUpdate(connectionState: .disconnected)
                sendUpdate(errorMessage: error.localizedDescription)
            }
        }
    }

    override func find() {
        guard let manager else {
            DirectLog.error("Guard: manager is nil")
            return
        }
        
        guard let serviceUUID else {
            DirectLog.error("Guard: serviceUUID is nil")
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
            managerQueue.asyncAfter(deadline: .now() + .seconds(5)) {
                self.find()
            }
        }
    }

    // MARK: Private

    private let pairingService: LibreNFC = .init()
}
