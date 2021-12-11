//
//  SensorConnector.swift
//  LibreDirect
//

import Combine
import Foundation

func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo]) -> Middleware<AppState, AppAction> {
    return sensorConnectorMiddelware(infos, calibrationService: CalibrationService())
}

private func sensorConnectorMiddelware(_ infos: [SensorConnectionInfo], calibrationService: CalibrationService) -> Middleware<AppState, AppAction> {
    return { store, action, _ in
        let updatesHandler: SensorConnectionHandler = { update -> Void in
            let dispatch = store.dispatch
            var action: AppAction?

            if let connectionUpdate = update as? SensorConnectionStateUpdate {
                action = .setConnectionState(connectionState: connectionUpdate.connectionState)

            } else if let readingUpdate = update as? SensorReadingUpdate {
                if let nextReading = readingUpdate.nextReading {
                    action = .addSensorReadings(nextReading: nextReading, trendReadings: readingUpdate.trendReadings, historyReadings: readingUpdate.historyReadings)
                } else {
                    action = .addMissedReading
                }

            } else if let stateUpdate = update as? SensorStateUpdate {
                action = .setSensorState(sensorAge: stateUpdate.sensorAge, sensorState: stateUpdate.sensorState)

            } else if let errorUpdate = update as? SensorErrorUpdate {
                action = .setConnectionError(errorMessage: errorUpdate.errorMessage, errorTimestamp: errorUpdate.errorTimestamp, errorIsCritical: errorUpdate.errorIsCritical)

            } else if let sensorUpdate = update as? SensorUpdate {
                if let sensor = sensorUpdate.sensor {
                    action = .setSensor(sensor: sensor)
                } else {
                    action = .resetSensor
                }
            } else if let transmitterUpdate = update as? SensorTransmitterUpdate {
                action = .setTransmitter(transmitter: transmitterUpdate.transmitter)
            }

            if let action = action {
                DispatchQueue.main.async {
                    dispatch(action)
                }
            }
        }

        switch action {
        case .startup:
            store.dispatch(.registerConnectionInfo(infos: infos))

            if let id = store.state.selectedConnectionId, let connectionInfo = infos.first(where: { $0.id == id }) {
                AppLog.info("Select startup connection: \(connectionInfo.name)")
                store.dispatch(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator()))

            } else if infos.count == 1, let connectionInfo = infos.first {
                AppLog.info("Select single startup connection: \(connectionInfo.name)")
                store.dispatch(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator()))

            } else if let connectionInfo = infos.first {
                AppLog.info("Select first startup connection: \(connectionInfo.name)")
                store.dispatch(.selectConnection(id: connectionInfo.id, connection: connectionInfo.connectionCreator()))
            }

        case .selectConnectionId(id: let id):
            if let connectionInfo = store.state.connectionInfos.first(where: { $0.id == id }) {
                let connection = connectionInfo.connectionCreator()
                store.dispatch(.selectConnection(id: id, connection: connection))
            }

        case .selectConnection(id: _, connection: _):
            if store.state.isPaired, store.state.isConnectable {
                store.dispatch(.connectSensor)
            }

        case .addSensorReadings(nextReading: let nextReading, trendReadings: let trendReadings, historyReadings: _):
            if let sensor = store.state.sensor, let glucose = calibrationService.calibrate(sensor: sensor, nextReading: nextReading, currentGlucose: store.state.currentGlucose) {
                guard store.state.currentGlucose == nil || store.state.currentGlucose!.timestamp < nextReading.timestamp else {
                    break
                }

                if store.state.glucoseValues.isEmpty {
                    let calibratedTrend = trendReadings.map { reading in
                        calibrationService.calibrate(sensor: sensor, nextReading: reading)
                    }.compactMap { $0 }

                    if trendReadings.isEmpty {
                        store.dispatch(.addGlucose(glucose: glucose))
                    } else {
                        store.dispatch(.addGlucoseValues(glucoseValues: calibratedTrend))
                    }
                } else {
                    store.dispatch(.addGlucose(glucose: glucose))
                }
            }

        case .pairSensor:
            guard let sensorConnection = store.state.selectedConnection else {
                break
            }

            sensorConnection.pairSensor(updatesHandler: updatesHandler)

        case .connectSensor:
            guard let sensorConnection = store.state.selectedConnection else {
                break
            }

            if let sensor = store.state.sensor {
                sensorConnection.connectSensor(sensor: sensor, updatesHandler: updatesHandler)
            } else {
                sensorConnection.pairSensor(updatesHandler: updatesHandler)
            }
            
        case .disconnectSensor:
            guard let sensorConnection = store.state.selectedConnection else {
                break
            }

            sensorConnection.disconnectSensor()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

typealias SensorConnectionCreator = () -> SensorConnection

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
