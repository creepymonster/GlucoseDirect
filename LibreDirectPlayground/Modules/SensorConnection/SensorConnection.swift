//
//  SensorConnection.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

class SensorUpdate {
}

class SensorAgeUpdate: SensorUpdate {
    private(set) var sensorAge: Int

    init(sensorAge: Int) {
        self.sensorAge = sensorAge
    }
}

class SensorConnectionUpdate: SensorUpdate {
    private(set) var connectionState: SensorConnectionState

    init(connectionState: SensorConnectionState) {
        self.connectionState = connectionState
    }
}

class SensorReadingUpdate: SensorUpdate {
    private(set) var lastGlucose: SensorGlucose

    init(lastGlucose: SensorGlucose) {
        self.lastGlucose = lastGlucose
    }
}

class SensorErrorUpdate: SensorUpdate {
    private(set) var errorMessage: String
    private(set) var errorTimestamp: Date = Date()

    init(errorMessage: String) {
        self.errorMessage = errorMessage
    }

    init(errorCode: Int) {
        self.errorMessage = translateError(errorCode: errorCode)
    }
}

protocol SensorConnectionProtocol {
    func subscribeForUpdates() -> AnyPublisher<SensorUpdate, Never>
    func connectSensor(sensor: Sensor)
    func disconnectSensor()
}

func sensorConnectionMiddelware(service: SensorConnectionProtocol) -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .subscribeForUpdates:
            return service.subscribeForUpdates()
                .subscribe(on: DispatchQueue.main)
                .map {
                if let connectionUpdate = $0 as? SensorConnectionUpdate {
                    return AppAction.setSensorConnection(connectionUpdate: connectionUpdate)

                } else if let readingUpdate = $0 as? SensorReadingUpdate {
                    return AppAction.setSensorReading(readingUpdate: readingUpdate)

                } else if let ageUpdate = $0 as? SensorAgeUpdate {
                    return AppAction.setSensorAge(ageUpdate: ageUpdate)

                } else if let errorUpdate = $0 as? SensorErrorUpdate {
                    return AppAction.setSensorError(errorUpdate: errorUpdate)
                }

                return AppAction.setSensorError(errorUpdate: SensorErrorUpdate(errorMessage: "Unknown error"))
            }.eraseToAnyPublisher()

        case .connectSensor:
            if let sensor = state.sensor {
                service.connectSensor(sensor: sensor)
            }

        case .disconnectSensor:
            service.disconnectSensor()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
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
