//
//  DefaultAppReducer.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation
import Combine

public func defaultAppReducer(state: inout AppState, action: AppAction) -> Void {
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

    case .setSensor(value: let value):
        state.sensor = value

    case .setSensorConnection(connectionState: let connectionState):
        state.connectionState = connectionState

        if resetableStates.contains(connectionState) {
            state.connectionError = nil
            state.connectionErrorTimeStamp = nil
        }

    case .setSensorReading(glucose: let glucose):
        if let lastGlucose = state.glucoseValues.last {
            let minutesBetweenValues = glucose.timestamp.timeIntervalSince(lastGlucose.timestamp) / 60
            //let allowedChange = Int(Double(lastGlucose.glucoseFiltered) * AppConfig.AllowedGlucoseChange * minutesBetweenValues)
            let allowedChange = Int(round(AppConfig.AllowedGlucoseChange * minutesBetweenValues))

            let lowerLimit = max(lastGlucose.glucoseFiltered - allowedChange, AppConfig.MinReadableGlucose)
            let upperLimit = min(lastGlucose.glucoseFiltered + allowedChange, AppConfig.MaxReadableGlucose)

            glucose.lowerLimits.append(lowerLimit)
            glucose.upperLimits.append(upperLimit)

            Log.info("Reading update current: \(glucose.glucoseFiltered), lowerLimit: \(lowerLimit), upperLimit: \(upperLimit)")
        }

        state.missedReadings = 0
        state.glucoseValues.append(glucose)

        if let numberOfGlucoseValues = AppConfig.NumberOfGlucoseValues {
            let toMany = state.glucoseValues.count - numberOfGlucoseValues
            if toMany > 0 {
                for _ in 1...toMany {
                    state.glucoseValues
                        .removeFirst()
                }
            }
        }

    case .setSensorAge(sensorAge: let sensorAge):
        guard state.sensor != nil else {
            return
        }

        state.sensor!.age = sensorAge

    case .setSensorMissedReadings:
        state.missedReadings += 1

    case .setSensorError(errorMessage: let errorMessage, errorTimestamp: let errorTimestamp):
        state.connectionError = errorMessage
        state.connectionErrorTimeStamp = errorTimestamp

    case .setNightscoutUpload(enabled: let enabled):
        state.nightscoutUpload = enabled

    case .setNightscoutHost(host: let host):
        state.nightscoutHost = host

    case .setNightscoutSecret(apiSecret: let apiSecret):
        state.nightscoutApiSecret = apiSecret

    case .setAlarmLow(value: let value):
        state.alarmLow = value

    case .setAlarmHigh(value: let value):
        state.alarmHigh = value

    case .setAlarmSnoozeUntil(value: let value):
        if let value = value {
            state.alarmSnoozeUntil = value

            // stop sounds
            NotificationCenterService.shared.stopSound()
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
