//
//  LibreConnection.swift
//  GlucoseDirectApp
//

import Combine
import Foundation

// MARK: - LibreConnection

class LibreConnection: SensorConnectionProtocol, IsSensor {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<DirectAction, DirectError>) {
        DirectLog.info("Init")

        self.subject = subject
    }

    // MARK: Internal

    weak var subject: PassthroughSubject<DirectAction, DirectError>?

    func pairConnection() {
        DirectLog.info("PairSensor")

        Task {
            sendUpdate(connectionState: .pairing)

            do {
                let result = try await pairingService.readSensor(enableStreaming: true)

                sendUpdate(connectionState: .disconnected)

                if let connection = initConnection(sensor: result.sensor) {
                    connection.pairConnection()
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

    func connectConnection(sensor: Sensor, sensorInterval: Int) {
        if let connection = initConnection(sensor: sensor) {
            connection.connectConnection(sensor: sensor, sensorInterval: sensorInterval)
        }
    }

    func disconnectConnection() {
        bluetoothConnection = nil
    }

    func getConfiguration() -> [SensorConnectionConfigurationOption]? {
        return bluetoothConnection?.getConfiguration()
    }

    // MARK: Private

    private let pairingService: LibreNFC = .init()
    private var bluetoothConnection: SensorBluetoothConnection?

    private func initConnection(sensor: Sensor) -> SensorBluetoothConnection? {
        guard let subject = subject else {
            return nil
        }

        if bluetoothConnection != nil {
            bluetoothConnection = nil
        }

        if sensor.type == .libre2EU {
            bluetoothConnection = Libre2Connection(subject: subject)
        } else if sensor.type == .libre3 {
            bluetoothConnection = LibreLinkUpConnection(subject: subject)
        }

        return bluetoothConnection
    }
}
