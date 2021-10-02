//
//  DeviceUpdate.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 02.10.21.
//

import Foundation

class DeviceServiceUpdate {
}

class DeviceServiceAgeUpdate: DeviceServiceUpdate {
    private(set) var sensorAge: Int

    init(sensorAge: Int) {
        self.sensorAge = sensorAge
    }
}

class DeviceServiceConnectionUpdate: DeviceServiceUpdate {
    private(set) var connectionState: SensorConnectionState

    init(connectionState: SensorConnectionState) {
        self.connectionState = connectionState
    }
}

class DeviceServiceSensorUpdate: DeviceServiceUpdate {
    private(set) var sensor: Sensor

    init(sensor: Sensor) {
        self.sensor = sensor
    }
}

class DeviceServiceGlucoseUpdate: DeviceServiceUpdate {
    private(set) var glucose: SensorGlucose?

    init(lastGlucose: SensorGlucose? = nil) {
        self.glucose = lastGlucose
    }
}

class DeviceServiceErrorUpdate: DeviceServiceUpdate {
    private(set) var errorMessage: String
    private(set) var errorTimestamp: Date = Date()

    init(errorMessage: String) {
        self.errorMessage = errorMessage
    }

    init(errorCode: Int) {
        self.errorMessage = translateError(errorCode: errorCode)
    }
}

fileprivate func translateError(errorCode: Int) -> String {
    switch errorCode {
    case 0: //case unknown = 0
        return "unknown"

    case 1: //case invalidParameters = 1
        return "invalidParameters"

    case 2: //case invalidHandle = 2
        return "invalidHandle"

    case 3: //case notConnected = 3
        return "notConnected"

    case 4: //case outOfSpace = 4
        return "outOfSpace"

    case 5: //case operationCancelled = 5
        return "operationCancelled"

    case 6: //case connectionTimeout = 6
        return "connectionTimeout"

    case 7: //case peripheralDisconnected = 7
        return "peripheralDisconnected"

    case 8: //case uuidNotAllowed = 8
        return "uuidNotAllowed"

    case 9: //case alreadyAdvertising = 9
        return "alreadyAdvertising"

    case 10: //case connectionFailed = 10
        return "connectionFailed"

    case 11: //case connectionLimitReached = 11
        return "connectionLimitReached"

    case 13: //case operationNotSupported = 13
        return "operationNotSupported"

    default:
        return ""
    }
}
