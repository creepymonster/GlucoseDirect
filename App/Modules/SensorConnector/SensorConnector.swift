//
//  SensorConnector.swift
//  GlucoseDirect
//

import Combine
import Foundation

func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo]) -> Middleware<DirectState, DirectAction> {
    return sensorConnectorMiddelware(infos, subject: PassthroughSubject<DirectAction, AppError>())
}

private func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo], subject: PassthroughSubject<DirectAction, AppError>) -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            let registerConnectionInfo = Just(DirectAction.registerConnectionInfo(infos: infos))
            var selectConnection: Just<DirectAction>?

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
            guard let lastReading = readings.last, lastReading.quality == .OK else {
                break
            }
            
            let readGlucoseValues = readings.map { reading in
                reading.calibrate(customCalibration: state.customCalibration)
            }.compactMap { $0 }

            let stdev = readGlucoseValues.count >= 5 ? readGlucoseValues.suffix(5).stdev : 0
            let intervalSeconds = Double(state.sensorInterval * 60 - 30)

            DirectLog.info("Stdev \(stdev) of \(readGlucoseValues.suffix(5).doubleValues)")

            var previousGlucose = state.sensorGlucoseValues.last
            let glucoseValues = readGlucoseValues.filter { reading in
                previousGlucose == nil || previousGlucose!.timestamp + intervalSeconds < reading.timestamp
            }.map {
                let glucose = $0.populateChange(previousGlucose: previousGlucose)
                previousGlucose = glucose

                return glucose
            }

            guard !glucoseValues.isEmpty else {
                break
            }

            guard stdev < 100 else {
                break
            }

            return Just(.addSensorGlucose(glucoseValues: glucoseValues))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

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
            guard isPaired, state.isConnectable else {
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
