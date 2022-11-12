//
//  SensorConnector.swift
//  GlucoseDirect
//

import Combine
import Foundation

func sensorErrorMiddleware() -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .addSensorReadings(readings: let readings):
            let previousError = state.sensorErrorValues.last
            let sensorErrors = readings.filter { reading in
                (previousError == nil || previousError!.timestamp < reading.timestamp) && reading.error != .OK
            }.map { reading in
                SensorError(timestamp: reading.timestamp, error: reading.error)
            }

            guard !sensorErrors.isEmpty else {
                break
            }

            return Just(.addSensorError(errorValues: sensorErrors))
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        default:
            break
        }
        return Empty().eraseToAnyPublisher()
    }
}

func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo]) -> Middleware<DirectState, DirectAction> {
    return sensorConnectorMiddelware(infos, subject: PassthroughSubject<DirectAction, DirectError>(), glucoseFilter: GlucoseFilter())
}

private func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo], subject: PassthroughSubject<DirectAction, DirectError>, glucoseFilter: GlucoseFilter) -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            var actions = [Just(DirectAction.registerConnectionInfo(infos: infos))]

            if let id = state.selectedConnectionID, let connectionInfo = infos.first(where: { $0.id == id }) {
                DirectLog.info("Select startup connection: \(connectionInfo.name)")
                actions.append(Just(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator(subject))))

            } else if infos.count == 1, let connectionInfo = infos.first {
                DirectLog.info("Select single startup connection: \(connectionInfo.name)")
                actions.append(Just(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator(subject))))

            } else if let connectionInfo = infos.first {
                DirectLog.info("Select first startup connection: \(connectionInfo.name)")
                actions.append(Just(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator(subject))))
            }

            return Publishers.MergeMany(actions)
                .setFailureType(to: DirectError.self)
                .merge(with: subject)
                .eraseToAnyPublisher()

        case .selectConnectionID(id: let id):
            if let connectionInfo = state.connectionInfos.first(where: { $0.id == id }) {
                let connection = connectionInfo.connectionCreator(subject)

                return Just(.selectConnection(id: id, connection: connection))
                    .setFailureType(to: DirectError.self)
                    .eraseToAnyPublisher()
            }

        case .selectConnection(id: _, connection: _):
            if state.isConnectionPaired, state.isConnectable {
                return Just(.connectConnection)
                    .setFailureType(to: DirectError.self)
                    .eraseToAnyPublisher()
            }

        case .addSensorReadings(readings: let readings):
            var previousGlucose = state.latestSensorGlucose

            // calibrate valid values
            let readGlucoseValues = readings.map { reading in
                reading.calibrate(customCalibration: state.customCalibration)
            }.compactMap { $0 }

            // calc stdev of last 5 values
            let stdev = readGlucoseValues.count >= 5 ? readGlucoseValues.suffix(5).stdev : 0
            let intervalSeconds = Double(state.sensorInterval * 60 - 15)

            // filter unwanted values
            let glucoseValues = readGlucoseValues.filter {
                previousGlucose == nil || previousGlucose!.timestamp + intervalSeconds < $0.timestamp
            }.map {
                SensorGlucose(id: $0.id, timestamp: $0.timestamp, rawGlucoseValue: $0.rawGlucoseValue, intGlucoseValue: $0.glucoseValue, smoothGlucoseValue: glucoseFilter.filter(glucoseValue: $0.glucoseValue))
                
            }.map {
                let glucose = $0.populateChange(previousGlucose: previousGlucose)
                previousGlucose = glucose

                return glucose
            }

            // stdev is over 100, only errors are saved
            guard !glucoseValues.isEmpty, stdev < 100 else {
                break
            }

            return Just(.addSensorGlucose(glucoseValues: glucoseValues))
                .setFailureType(to: DirectError.self)
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
                    .setFailureType(to: DirectError.self)
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
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}
