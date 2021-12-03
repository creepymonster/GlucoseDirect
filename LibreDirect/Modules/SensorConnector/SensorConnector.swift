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
                action = .setConnectionError(errorMessage: errorUpdate.errorMessage, errorTimestamp: errorUpdate.errorTimestamp)

            } else if let sensorUpdate = update as? SensorUpdate {
                action = .setSensor(sensor: sensorUpdate.sensor)
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
                Log.info("Select startup connection: \(connectionInfo.name)")
                store.dispatch(.selectedConnection(id: connectionInfo.id, connection: connectionInfo.connectionType.init()))

            } else if infos.count == 1, let connectionInfo = infos.first {
                Log.info("Select single startup connection: \(connectionInfo.name)")
                store.dispatch(.selectedConnection(id: connectionInfo.id, connection: connectionInfo.connectionType.init()))

            } else if let connectionInfo = infos.first {
                Log.info("Select first startup connection: \(connectionInfo.name)")
                store.dispatch(.selectedConnection(id: connectionInfo.id, connection: connectionInfo.connectionType.init()))
            }

        case .selectedConnectionId(id: let id):
            // if let sensorConnection = store.state.selectedConnection {
            // sensorConnection.disconnectSensor()
            // }

            if let connectionInfo = store.state.connectionInfos.first(where: { $0.id == id }) {
                let connection = connectionInfo.connectionType.init()
                store.dispatch(.selectedConnection(id: id, connection: connection))
            }

        case .selectedConnection(id: _, connection: _):
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

            guard let sensor = store.state.sensor else {
                break
            }

            sensorConnection.connectSensor(sensor: sensor, updatesHandler: updatesHandler)
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
