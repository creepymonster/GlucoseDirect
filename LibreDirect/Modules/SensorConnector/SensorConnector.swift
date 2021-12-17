//
//  SensorConnector.swift
//  LibreDirect
//

import Combine
import Foundation

func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo]) -> Middleware<AppState, AppAction> {
    return sensorConnectorMiddelware(infos, subject: PassthroughSubject<AppAction, AppError>(), calibrationService: CalibrationService())
}

private func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo], subject: PassthroughSubject<AppAction, AppError>, calibrationService: CalibrationService) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            let registerConnectionInfo = Just(AppAction.registerConnectionInfo(infos: infos))
            var selectConnection: Just<AppAction>? = nil

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

        case .addSensorReadings(nextReading: let nextReading, trendReadings: let trendReadings, historyReadings: _):
            if let sensor = state.sensor, let glucose = calibrationService.calibrate(sensor: sensor, nextReading: nextReading, currentGlucose: state.currentGlucose) {
                guard state.currentGlucose == nil || state.currentGlucose!.timestamp < nextReading.timestamp else {
                    break
                }

                if state.glucoseValues.isEmpty {
                    let calibratedTrend = trendReadings.map { reading in
                        calibrationService.calibrate(sensor: sensor, nextReading: reading)
                    }.compactMap { $0 }

                    if trendReadings.isEmpty {
                        return Just(.addGlucose(glucose: glucose))
                            .setFailureType(to: AppError.self)
                            .eraseToAnyPublisher()

                    } else {
                        return Just(.addGlucoseValues(glucoseValues: calibratedTrend))
                            .setFailureType(to: AppError.self)
                            .eraseToAnyPublisher()
                    }
                } else {
                    return Just(.addGlucose(glucose: glucose))
                        .setFailureType(to: AppError.self)
                        .eraseToAnyPublisher()
                }
            }

        case .pairSensor:
            guard let sensorConnection = state.selectedConnection else {
                break
            }

            sensorConnection.pairSensor()

        case .connectSensor:
            guard let sensorConnection = state.selectedConnection else {
                break
            }

            if let sensor = state.sensor {
                sensorConnection.connectSensor(sensor: sensor)
            } else {
                sensorConnection.pairSensor()
            }

        case .disconnectSensor:
            guard let sensorConnection = state.selectedConnection else {
                break
            }

            sensorConnection.disconnectSensor()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

typealias SensorConnectionCreator = (PassthroughSubject<AppAction, AppError>) -> SensorConnection

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
