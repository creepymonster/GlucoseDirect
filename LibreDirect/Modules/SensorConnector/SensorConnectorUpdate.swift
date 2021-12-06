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
        self.errorMessage = errorMessage
    }

    init(errorCode: Int) {
        self.errorMessage = SensorErrorUpdate.translateError(errorCode: errorCode)
    }

    // MARK: Internal

    let errorMessage: String
    let errorTimestamp = Date()

    // MARK: Private

    private static func translateError(errorCode: Int) -> String {
        switch errorCode {
        case 0: // case unknown = 0
            return "unknown"

        case 1: // case invalidParameters = 1
            return "invalidParameters"

        case 2: // case invalidHandle = 2
            return "invalidHandle"

        case 3: // case notConnected = 3
            return "notConnected"

        case 4: // case outOfSpace = 4
            return "outOfSpace"

        case 5: // case operationCancelled = 5
            return "operationCancelled"

        case 6: // case connectionTimeout = 6
            return "connectionTimeout"

        case 7: // case peripheralDisconnected = 7
            return "peripheralDisconnected"

        case 8: // case uuidNotAllowed = 8
            return "uuidNotAllowed"

        case 9: // case alreadyAdvertising = 9
            return "alreadyAdvertising"

        case 10: // case connectionFailed = 10
            return "connectionFailed"

        case 11: // case connectionLimitReached = 11
            return "connectionLimitReached"

        case 13: // case operationNotSupported = 13
            return "operationNotSupported"

        default:
            return ""
        }
    }
}
