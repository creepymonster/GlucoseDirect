//
//  SensorConnector.swift
//  GlucoseDirect
//

import Combine
import Foundation

func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo]) -> Middleware<AppState, AppAction> {
    return sensorConnectorMiddelware(infos, subject: PassthroughSubject<AppAction, AppError>())
}

private func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo], subject: PassthroughSubject<AppAction, AppError>) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            let registerConnectionInfo = Just(AppAction.registerConnectionInfo(infos: infos))
            var selectConnection: Just<AppAction>?

            if let id = state.selectedConnectionID, let connectionInfo = infos.first(where: { $0.id == id }) {
                DirectLog.info("Select startup connection: \(connectionInfo.name)")
                selectConnection = Just(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator(subject)))

            } else if infos.count == 1, let connectionInfo = infos.first {
                DirectLog.info("Select single startup connection: \(connectionInfo.name)")
                selectConnection = Just(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator(subject)))

            } else if let connectionInfo = infos.first {
                DirectLog.info("Select first startup connection: \(connectionInfo.name)")
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

        case .selectConnectionID(id: let id):
            if let connectionInfo = state.connectionInfos.first(where: { $0.id == id }) {
                let connection = connectionInfo.connectionCreator(subject)

                return Just(.selectConnection(id: id, connection: connection))
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }

        case .selectConnection(id: _, connection: _):
            if state.isConnectionPaired, state.isConnectable {
                return Just(.connectConnection)
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }

        case .addSensorReadings(sensorSerial: _, readings: let readings):
            if !readings.isEmpty {
                let glucoseValues = readings.map { reading in
                    reading.calibrate(customCalibration: state.customCalibration)
                }

                guard let latestGlucose = glucoseValues.last else {
                    break
                }

                guard let latestRawGlucoseValue = latestGlucose.rawGlucoseValue,
                      let latestGlucoseValue = latestGlucose.glucoseValue,
                      latestGlucose.type == .cgm
                else {
                    return Just(.addGlucose(glucose: latestGlucose))
                        .setFailureType(to: AppError.self)
                        .eraseToAnyPublisher()
                }

                if let currentGlucose = state.latestSensorGlucose, currentGlucose.timestamp >= latestGlucose.timestamp {
                    break
                }

                let filteredGlucose = glucoseValues.filter { glucose in
                    glucose.type == .cgm && glucose.glucoseValue != nil
                }

                let summedGlucose = latestGlucoseValue + filteredGlucose.map { glucose in
                    glucose.glucoseValue!
                }.reduce(0, +)

                return Just(.addGlucose(glucose:
                    Glucose
                        .createSensorGlucose(timestamp: latestGlucose.timestamp, rawGlucoseValue: latestRawGlucoseValue, glucoseValue: Int(Double(summedGlucose) / Double(1 + filteredGlucose.count)), minuteChange: nil)
                        .populateChange(previousGlucose: state.latestSensorGlucose)
                ))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()
            }

        case .pairConnection:
            guard let sensorConnection = state.selectedConnection else {
                DirectLog.info("Guard: state.selectedConnection is nil")
                break
            }

            sensorConnection.pairConnection()

        case .setSensorInterval(interval: _):
            if state.isDisconnectable, let sensorConnection = state.selectedConnection {
                sensorConnection.disconnectConnection()

                return Just(.connectConnection)
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }

        case .connectConnection:
            guard let sensorConnection = state.selectedConnection else {
                DirectLog.info("Guard: state.selectedConnection is nil")
                break
            }

            if let sensor = state.sensor {
                sensorConnection.connectConnection(sensor: sensor, sensorInterval: state.sensorInterval)
            } else {
                sensorConnection.pairConnection()
            }

        case .disconnectConnection:
            guard let sensorConnection = state.selectedConnection else {
                DirectLog.info("Guard: state.selectedConnection is nil")
                break
            }

            sensorConnection.disconnectConnection()

        case .setConnectionPaired(isPaired: let isPaired):
            guard isPaired && state.isConnectable else {
                DirectLog.info("Guard: sensor was not paired, no auto connect")
                break
            }

            return Just(.connectConnection)
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

// TEST
