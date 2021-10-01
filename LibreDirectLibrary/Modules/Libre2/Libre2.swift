//
//  Libre2.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation
import Combine

@available(iOS 13.0, *)
public func libre2Middelware() -> Middleware<AppState, AppAction> {
    return libre2Middelware(pairingService: Libre2PairingService(), connectionService: Libre2ConnectionService())
}

@available(iOS 13.0, *)
fileprivate func libre2Middelware(pairingService: Libre2PairingService, connectionService: Libre2ConnectionService) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .pairSensor:
            pairingService.pairSensor() { (uuid, patchInfo, fram, streamingEnabled) -> Void in
                let dispatch = store.dispatch

                if streamingEnabled {
                    DispatchQueue.main.async {
                        UserDefaults.standard.libre2UnlockCount = 0

                        dispatch(.setSensor(value: Sensor(uuid: uuid, patchInfo: patchInfo, fram: fram)))
                        dispatch(.connectSensor)
                    }
                }
            }

        case .connectSensor:
            if let sensor = store.state.sensor {
                connectionService.connectSensor(sensor: sensor) { (update) -> Void in
                    let dispatch = store.dispatch
                    var action: AppAction? = nil

                    if let connectionUpdate = update as? DeviceConnectionUpdate {
                        action = .setSensorConnection(connectionState: connectionUpdate.connectionState)

                    } else if let readingUpdate = update as? DeviceGlucoseUpdate {
                        if let glucose = readingUpdate.glucose {
                            action = .setSensorReading(glucose: glucose)
                        } else {
                            action = .setSensorMissedReadings
                        }

                    } else if let ageUpdate = update as? DeviceAgeUpdate {
                        action = .setSensorAge(sensorAge: ageUpdate.sensorAge)

                    } else if let errorUpdate = update as? DeviceErrorUpdate {
                        action = .setSensorError(errorMessage: errorUpdate.errorMessage, errorTimestamp: errorUpdate.errorTimestamp)
                        
                    } else if let sensorUpdate = update as? DeviceSensorUpdate {
                        action = .setSensor(value: sensorUpdate.sensor)
                        
                    }

                    if let action = action {
                        DispatchQueue.main.async {
                            dispatch(action)
                        }
                    }
                }
            }

        case .disconnectSensor:
            connectionService.disconnectSensor()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

extension UserDefaults {
    fileprivate enum Keys: String {
        case libre2UnlockCount = "libre-direct.libre2.unlock-count"
    }
    
    var libre2UnlockCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.libre2UnlockCount.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.libre2UnlockCount.rawValue)
        }
    }
}
