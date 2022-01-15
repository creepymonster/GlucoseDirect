//
//  SensorConnector.swift
//  LibreDirect
//

import Combine
import Foundation

func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo]) -> Middleware<AppState, AppAction> {
    return sensorConnectorMiddelware(infos, subject: PassthroughSubject<AppAction, AppError>(), calibrationService: {
        CalibrationService()
    }())
}

private func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo], subject: PassthroughSubject<AppAction, AppError>, calibrationService: CalibrationService) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            let registerConnectionInfo = Just(AppAction.registerConnectionInfo(infos: infos))
            var selectConnection: Just<AppAction>?

            if let id = state.selectedConnectionId, let connectionInfo = infos.first(where: { $0.id == id }) {
                AppLog.info("Select startup connection: \(connectionInfo.name)")
                selectConnection = Just(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator(subject)))

            } else if infos.count == 1, let connectionInfo = infos.first {
                AppLog.info("Select single startup connection: \(connectionInfo.name)")
                selectConnection = Just(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator(subject)))

            } else if let connectionInfo = infos.first {
                AppLog.info("Select first startup connection: \(connectionInfo.name)")
                selectConnection = Just(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator(subject)))
            }

            if let selectConnection = selectConnection {
                return registerConnectionInfo
                    .merge(with: selectConnection)
                    .setFailureType(to: AppError.self)
                    .merge(with: subject)
                    .eraseToAnyPublisher()
            }

            return registerConnectionInfo
                .setFailureType(to: AppError.self)
                .merge(with: subject)
                .eraseToAnyPublisher()

        case .selectConnectionId(id: let id):
            if let connectionInfo = state.connectionInfos.first(where: { $0.id == id }) {
                let connection = connectionInfo.connectionCreator(subject)

                return Just(.selectConnection(id: id, connection: connection))
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }

        case .selectConnection(id: _, connection: _):
            if state.isPaired, state.isConnectable {
                return Just(.connectSensor)
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }

        case .addSensorReadings(sensorSerial: _, trendReadings: let trendReadings, historyReadings: let historyReadings):
            if !trendReadings.isEmpty, !historyReadings.isEmpty {
                let missingHistory = historyReadings.filter { reading in
                    if state.currentGlucose == nil || reading.timestamp > state.currentGlucose!.timestamp, reading.timestamp < trendReadings.first!.timestamp {
                        return true
                    }

                    return false
                }

                let missingTrend = trendReadings
                    .filter { reading in
                        if state.currentGlucose == nil || reading.timestamp > state.currentGlucose!.timestamp {
                            return true
                        }

                        return false
                    }

                var previousGlucose = state.currentGlucose
                var missedGlucosValues: [Glucose] = []

                missingHistory.forEach { reading in
                    let glucose = calibrationService.calibrate(customCalibration: state.customCalibration, nextReading: reading, currentGlucose: previousGlucose)
                    missedGlucosValues.append(glucose)

                    if glucose.quality == .OK {
                        previousGlucose = glucose
                    }
                }

                missingTrend.forEach { reading in
                    let glucose = calibrationService.calibrate(customCalibration: state.customCalibration, nextReading: reading, currentGlucose: previousGlucose)
                    missedGlucosValues.append(glucose)

                    if glucose.quality == .OK {
                        previousGlucose = glucose
                    }
                }

                return Just(.addGlucoseValues(glucoseValues: missedGlucosValues))
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }
            
        case .scanSensor:
            guard let sensorConnection = state.selectedConnection else {
                AppLog.info("Guard: state.selectedConnection is nil")
                break
            }

            if let sensorConnection = sensorConnection as? SensorNFCConnection {
                AppLog.info("no Pairing: \(!state.isPaired)")
                sensorConnection.scanSensor(noPairing: state.isPaired)
            }

        case .pairSensor:
            guard let sensorConnection = state.selectedConnection else {
                AppLog.info("Guard: state.selectedConnection is nil")
                break
            }

            sensorConnection.pairSensor()
            
        case .setSensorInterval(interval: _):
            if state.isDisconnectable, let sensorConnection = state.selectedConnection {
                sensorConnection.disconnectSensor()
                
                return Just(.connectSensor)
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }

        case .connectSensor:
            guard let sensorConnection = state.selectedConnection else {
                AppLog.info("Guard: state.selectedConnection is nil")
                break
            }

            if let sensor = state.sensor {
                sensorConnection.connectSensor(sensor: sensor, sensorInterval: state.sensorInterval)
            } else {
                sensorConnection.pairSensor()
            }

        case .disconnectSensor:
            guard let sensorConnection = state.selectedConnection else {
                AppLog.info("Guard: state.selectedConnection is nil")
                break
            }

            sensorConnection.disconnectSensor()
            
        case .setSensor(sensor: _, wasPaired: let wasPaired):
            guard wasPaired else {
                AppLog.info("Guard: sensor was not paired, no auto connect")
                break
            }
            
            return Just(.connectSensor)
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

typealias SensorConnectionCreator = (PassthroughSubject<AppAction, AppError>) -> SensorBLEConnection

// MARK: - SensorConnectionInfo

class SensorConnectionInfo: Identifiable {
    // MARK: Lifecycle

    init(id: String, name: String, connectionCreator: @escaping SensorConnectionCreator) {
        self.id = id
        self.name = name
        self.connectionCreator = connectionCreator
    }

    // MARK: Internal

    let id: String
    let name: String
    let connectionCreator: SensorConnectionCreator
}
