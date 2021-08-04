//
//  DefaultAppReducer.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

func defaultAppReducer(state: inout AppState, action: AppAction) -> Void {
    switch action {
    case .connectSensor:
        break

    case .disconnectSensor:
        break

    case .pairSensor:
        break

    case .resetSensor:
        state.sensor = nil
        state.connectionError = nil
        state.glucoseValues = []       

    case .setSensor(value: let value):
        state.sensor = value

    case .setSensorConnection(connectionUpdate: let connectionUpdate):
        state.connectionState = connectionUpdate.connectionState

        if resetableStates.contains(connectionUpdate.connectionState) {
            state.connectionError = nil
            state.connectionErrorTimeStamp = nil
        }

    case .setSensorReading(readingUpdate: let readingUpdate):
        if let lastGlucose = state.glucoseValues.last {
            let minutesBetweenValues = readingUpdate.glucose.timeStamp.timeIntervalSince(lastGlucose.timeStamp) / 60
            let allowedChange = Int(Double(lastGlucose.glucoseFiltered) * AppConfig.AllowedGlucoseChangePerMinute * minutesBetweenValues)
            
            let lowerLimit = max(lastGlucose.glucoseFiltered - allowedChange, AppConfig.MinReadableGlucose)
            let upperLimit = min(lastGlucose.glucoseFiltered + allowedChange, AppConfig.MaxReadableGlucose)
            
            readingUpdate.glucose.lowerLimits.append(lowerLimit)
            readingUpdate.glucose.upperLimits.append(upperLimit)
            
            Log.info("Reading update current: \(readingUpdate.glucose.glucoseFiltered), lowerLimit: \(lowerLimit), upperLimit: \(upperLimit)")
        }
        
        state.glucoseValues.append(readingUpdate.glucose)

        if let numberOfGlucoseValues = AppConfig.numberOfGlucoseValues {
            let toMany = state.glucoseValues.count - numberOfGlucoseValues
            if toMany > 0 {
                for _ in 1...toMany {
                    state.glucoseValues
                        .removeFirst()
                }
            }
        }

    case .setSensorAge(ageUpdate: let ageUpdate):
        guard state.sensor != nil else {
            return
        }

        state.sensor!.age = ageUpdate.sensorAge

    case .setSensorError(errorUpdate: let errorUpdate):
        state.connectionError = errorUpdate.errorMessage
        state.connectionErrorTimeStamp = errorUpdate.errorTimestamp

    case .setNightscoutHost(host: let host):
        state.nightscoutHost = host

    case .setNightscoutSecret(apiSecret: let apiSecret):
        state.nightscoutApiSecret = apiSecret

    case .subscribeForUpdates:
        break

    case .setAlarmLow(value: let value):
        state.alarmLow = value

    case .setAlarmHigh(value: let value):
        state.alarmHigh = value

    case .setAlarmSnoozeUntil(value: let value):
        if let value = value {
            state.alarmSnoozeUntil = value
        } else {
            state.alarmSnoozeUntil = nil
        }
        
    case .setGlucoseUnit(value: let value):
        state.glucoseUnit = value
        
    }

    if let alarmSnoozeUntil = state.alarmSnoozeUntil, Date() > alarmSnoozeUntil {
        state.alarmSnoozeUntil = nil
    }
}

fileprivate var resetableStates: Set<SensorConnectionState> = [.connected, .powerOff, .scanning]
fileprivate var disconnectedStates: Set<SensorConnectionState> = [.disconnected, .scanning]
