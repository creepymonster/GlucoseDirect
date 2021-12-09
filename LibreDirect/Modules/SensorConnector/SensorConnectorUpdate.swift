//
//  DeviceUpdate.swift
//  LibreDirect
//

import Foundation

// MARK: - SensorConnectorUpdate

class SensorConnectorUpdate {}

// MARK: - SensorTransmitterUpdate

class SensorTransmitterUpdate: SensorConnectorUpdate {
    // MARK: Lifecycle

    init(transmitter: Transmitter) {
        self.transmitter = transmitter
    }

    // MARK: Internal

    let transmitter: Transmitter
}

// MARK: - SensorStateUpdate

class SensorStateUpdate: SensorConnectorUpdate {
    // MARK: Lifecycle

    init(sensorAge: Int, sensorState: SensorState?) {
        self.sensorAge = sensorAge
        self.sensorState = sensorState
    }

    // MARK: Internal

    let sensorAge: Int
    let sensorState: SensorState?
}

// MARK: - SensorConnectionStateUpdate

class SensorConnectionStateUpdate: SensorConnectorUpdate {
    // MARK: Lifecycle

    init(connectionState: SensorConnectionState) {
        self.connectionState = connectionState
    }

    // MARK: Internal

    let connectionState: SensorConnectionState
}

// MARK: - SensorUpdate

class SensorUpdate: SensorConnectorUpdate {
    // MARK: Lifecycle

    init(sensor: Sensor?) {
        self.sensor = sensor
    }

    // MARK: Internal

    let sensor: Sensor?
}

// MARK: - SensorReadingUpdate

class SensorReadingUpdate: SensorConnectorUpdate {
    // MARK: Lifecycle

    init(nextReading: SensorReading?, trendReadings: [SensorReading] = [], historyReadings: [SensorReading] = []) {
        self.nextReading = nextReading
        self.trendReadings = trendReadings
        self.historyReadings = historyReadings
    }

    // MARK: Internal

    let nextReading: SensorReading?
    let trendReadings: [SensorReading]
    let historyReadings: [SensorReading]
}

// MARK: - SensorErrorUpdate

class SensorErrorUpdate: SensorConnectorUpdate {
    // MARK: Lifecycle
    
    init(errorMessage: String) {
        self.errorCode = 0
        self.errorMessage = errorMessage
        self.errorIsCritical = false
    }

    init(errorCode: Int, errorIsCritical: Bool = false) {
        self.errorCode = errorCode
        self.errorMessage = SensorErrorUpdate.translateError(errorCode: errorCode)
        self.errorIsCritical = errorIsCritical
    }

    // MARK: Internal

    let errorCode: Int
    let errorMessage: String
    let errorTimestamp = Date()
    let errorIsCritical: Bool

    // MARK: Private

    private static func translateError(errorCode: Int) -> String {
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
}
