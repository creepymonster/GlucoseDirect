//
//  SensorConnection.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - SensorConnection

protocol SensorConnection {
    var subject: PassthroughSubject<AppAction, AppError>? { get }
}

// MARK: - SensorBLEConnection

protocol SensorBLEConnection: SensorConnection {
    func pairSensor()
    func connectSensor(sensor: Sensor)
    func disconnectSensor()
}

// MARK: - SensorNFCConnection

protocol SensorNFCConnection: SensorConnection {
    func scanSensor()
}

extension SensorBLEConnection {
    func sendUpdate(connectionState: SensorConnectionState) {
        AppLog.info("ConnectionState: \(connectionState.description)")

        subject?.send(.setConnectionState(connectionState: connectionState))
    }

    func sendUpdate(sensor: Sensor?, wasCoupled: Bool = false) {
        AppLog.info("Sensor: \(sensor?.description ?? "-")")

        if let sensor = sensor {
            subject?.send(.setSensor(sensor: sensor, wasCoupled: wasCoupled))
        } else {
            subject?.send(.resetSensor)
        }
    }

    func sendUpdate(transmitter: Transmitter) {
        AppLog.info("Transmitter: \(transmitter.description)")

        subject?.send(.setTransmitter(transmitter: transmitter))
    }

    func sendUpdate(age: Int, state: SensorState) {
        AppLog.info("SensorAge: \(age.description)")

        subject?.send(.setSensorState(sensorAge: age, sensorState: state))
    }

    func sendUpdate(sensorSerial: String, nextReading: SensorReading?) {
        AppLog.info("NextReading: \(nextReading)")

        if let nextReading = nextReading {
            subject?.send(.addSensorReadings(sensorSerial: sensorSerial, trendReadings: [nextReading], historyReadings: []))
        } else {
            subject?.send(.addMissedReading)
        }
    }

    func sendUpdate(sensorSerial: String, trendReadings: [SensorReading] = [], historyReadings: [SensorReading] = []) {
        AppLog.info("SensorTrendReadings: \(trendReadings)")
        AppLog.info("SensorHistoryReadings: \(historyReadings)")

        if !trendReadings.isEmpty, !historyReadings.isEmpty {
            subject?.send(.addSensorReadings(sensorSerial: sensorSerial, trendReadings: trendReadings, historyReadings: historyReadings))
        } else {
            subject?.send(.addMissedReading)
        }
    }

    func sendUpdate(error: Error?) {
        guard let error = error else {
            return
        }

        if let errorCode = CBError.Code(rawValue: (error as NSError).code) {
            sendUpdate(errorCode: errorCode.rawValue, errorIsCritical: errorCode.rawValue == 7)
        } else {
            sendUpdate(errorMessage: error.localizedDescription)
        }
    }

    func sendUpdate(errorMessage: String) {
        AppLog.error("ErrorMessage: \(errorMessage)")

        subject?.send(.setConnectionError(errorMessage: errorMessage, errorTimestamp: Date(), errorIsCritical: false))
    }

    func sendUpdate(errorCode: Int, errorIsCritical: Bool = false) {
        AppLog.error("ErrorCode: \(errorCode)")

        subject?.send(.setConnectionError(errorMessage: translateError(errorCode), errorTimestamp: Date(), errorIsCritical: false))
    }

    func sendMissedUpdate() {
        AppLog.error("Missed update")

        subject?.send(.addMissedReading)
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
