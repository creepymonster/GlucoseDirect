//
//  SensorConnection.swift
//  GlucoseDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - IsSensor

protocol IsSensor {}

// MARK: - IsTransmitter

protocol IsTransmitter {}

// MARK: - SensorConnectionProtocol

protocol SensorConnectionProtocol {
    var subject: PassthroughSubject<DirectAction, DirectError>? { get }
    func pairConnection()
    func connectConnection(sensor: Sensor, sensorInterval: Int)
    func disconnectConnection()
}

extension SensorConnectionProtocol {
    func sendUpdate(connectionState: SensorConnectionState) {
        DirectLog.info("ConnectionState: \(connectionState.description)")

        subject?.send(.setConnectionState(connectionState: connectionState))
    }

    func sendUpdate(isPaired: Bool) {
        DirectLog.info("IsPaired: \(isPaired)")

        subject?.send(.setConnectionPaired(isPaired: isPaired))
    }

    func sendUpdate(sensor: Sensor?, keepDevice: Bool = false) {
        DirectLog.info("Sensor: \(sensor?.description ?? "-")")

        if let sensor = sensor {
            subject?.send(.setSensor(sensor: sensor, keepDevice: keepDevice))
        } else {
            subject?.send(.resetSensor)
        }
    }

    func sendUpdate(transmitter: Transmitter) {
        DirectLog.info("Transmitter: \(transmitter.description)")

        subject?.send(.setTransmitter(transmitter: transmitter))
    }

    func sendUpdate(age: Int, state: SensorState) {
        DirectLog.info("SensorAge: \(age.description)")

        subject?.send(.setSensorState(sensorAge: age, sensorState: state))
    }

    func sendUpdate(sensorSerial: String, reading: SensorReading?) {
        if let reading = reading {
            sendUpdate(sensorSerial: sensorSerial, readings: [reading])
        } else {
            sendUpdate(sensorSerial: sensorSerial, readings: [])
        }
    }

    func sendUpdate(sensorSerial: String, readings: [SensorReading] = []) {
        DirectLog.info("SensorReadings: \(readings)")

        if !readings.isEmpty {
            subject?.send(.addSensorReadings(readings: readings))
        }
    }

    func sendUpdate(error: Error?) {
        guard let error = error else {
            return
        }
        
        DirectLog.error("Error: \(error.localizedDescription)")

        if let errorCode = CBError.Code(rawValue: (error as NSError).code) {
            if errorCode.rawValue == 7 {
                sendUpdate(errorMessage: LocalizedString("Rescan the sensor"), errorIsCritical: true)
            } else {
                sendUpdate(errorMessage: LocalizedString("Connection timeout"), errorIsCritical: true)
            }
        }
    }

    func sendUpdate(errorMessage: String, errorIsCritical: Bool = false) {
        DirectLog.error("ErrorMessage: \(errorMessage)")

        subject?.send(.setConnectionError(errorMessage: errorMessage, errorTimestamp: Date(), errorIsCritical: false))
    }

    func sendUpdate(peripheralUUID: String?) {
        DirectLog.info("PeripheralUUID: \(peripheralUUID)")

        subject?.send(.setConnectionPeripheralUUID(peripheralUUID: peripheralUUID))
    }
}

private func translateError(_ errorCode: Int) -> String {
    switch errorCode {
    case 0: // case unknown = 0
        return LocalizedString("Unknown")

    case 1: // case invalidParameters = 1
        return LocalizedString("Invalid parameters")

    case 2: // case invalidHandle = 2
        return LocalizedString("Invalid handle")

    case 3: // case notConnected = 3
        return LocalizedString("Not connected")

    case 4: // case outOfSpace = 4
        return LocalizedString("Out of space")

    case 5: // case operationCancelled = 5
        return LocalizedString("Operation cancelled")

    case 6: // case connectionTimeout = 6
        return LocalizedString("Connection timeout")

    case 7: // case peripheralDisconnected = 7
        return LocalizedString("Peripheral disconnected")

    case 8: // case uuidNotAllowed = 8
        return LocalizedString("UUID not allowed")

    case 9: // case alreadyAdvertising = 9
        return LocalizedString("Already advertising")

    case 10: // case connectionFailed = 10
        return LocalizedString("Connection failed")

    case 11: // case connectionLimitReached = 11
        return LocalizedString("Connection limit reached")

    case 13: // case operationNotSupported = 13
        return LocalizedString("Operation not supported")

    default:
        return ""
    }
}
