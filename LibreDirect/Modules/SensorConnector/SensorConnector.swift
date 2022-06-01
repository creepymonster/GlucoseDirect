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
            var selectConnection: Just<AppAction>?

            if let id = state.selectedConnectionID, let connectionInfo = infos.first(where: { $0.id == id }) {
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
                let calibratedGlucose = readings.map { reading in
                    calibrationService.withCalibration(customCalibration: state.customCalibration, reading: reading)
                }

                guard let lastCalibratedGlucose = calibratedGlucose.last else {
                    break
                }

                guard let lastCalibratedGlucoseValue = lastCalibratedGlucose.glucoseValue, lastCalibratedGlucose.quality == .OK else {
                    return Just(.addGlucoseValues(glucoseValues: [lastCalibratedGlucose]))
                        .setFailureType(to: AppError.self)
                        .eraseToAnyPublisher()
                }
                
                if let currentGlucose = state.currentGlucose, currentGlucose.timestamp >= lastCalibratedGlucose.timestamp {
                    break
                }

                let filteredGlucose = calibratedGlucose.filter { glucose in
                    glucose.quality == .OK && glucose.glucoseValue != nil
                }

                let summedGlucose = lastCalibratedGlucoseValue + filteredGlucose.map { glucose in
                    glucose.glucoseValue!
                }.reduce(0, +)

                let nextGlucose = Glucose(
                    id: lastCalibratedGlucose.id,
                    timestamp: lastCalibratedGlucose.timestamp,
                    initialGlucoseValue: lastCalibratedGlucose.initialGlucoseValue,
                    calibratedGlucoseValue: Int(Double(summedGlucose) / Double(1 + filteredGlucose.count)),
                    type: lastCalibratedGlucose.type,
                    quality: lastCalibratedGlucose.quality
                )

                return Just(.addGlucoseValues(glucoseValues: [
                    calibrationService.withMinuteChange(nextGlucose: nextGlucose, previousGlucose: state.currentGlucose)
                ]))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()
            }

        case .pairConnection:
            guard let sensorConnection = state.selectedConnection else {
                AppLog.info("Guard: state.selectedConnection is nil")
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
                AppLog.info("Guard: state.selectedConnection is nil")
                break
            }

            if let sensor = state.sensor {
                sensorConnection.connectConnection(sensor: sensor, sensorInterval: state.sensorInterval)
            } else {
                sensorConnection.pairConnection()
            }

        case .disconnectConnection:
            guard let sensorConnection = state.selectedConnection else {
                AppLog.info("Guard: state.selectedConnection is nil")
                break
            }

            sensorConnection.disconnectConnection()

        case .setConnectionPaired(isPaired: let isPaired):
            guard isPaired && state.isConnectable else {
                AppLog.info("Guard: sensor was not paired, no auto connect")
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
