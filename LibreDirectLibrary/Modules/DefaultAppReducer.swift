//
//  DefaultAppReducer.swift
//  LibreDirect
//

import Combine
import Foundation

func defaultAppReducer(state: inout AppState, action: AppAction) {
    switch action {
    case .addCalibration(bloodGlucose: let bloodGlucose):
        if let factoryCalibratedGlucoseValue = state.currentGlucose?.factoryCalibratedGlucoseValue {
            state.sensor?.customCalibration.append(CustomCalibration(x: Double(factoryCalibratedGlucoseValue), y: Double(bloodGlucose)))
        }
        
    case .removeCalibration(offsets: let offsets):
        if state.sensor != nil {
            state.sensor!.customCalibration.remove(atOffsets: offsets)
        }

    case .clearCalibrations:
        state.sensor?.customCalibration = []

    case .connectSensor:
        break

    case .disconnectSensor:
        break

    case .pairSensor:
        break

    case .resetSensor:
        state.sensor = nil
        state.connectionError = nil

    case .setAlarmHigh(value: let value):
        state.alarmHigh = value

    case .setAlarmLow(value: let value):
        state.alarmLow = value

    case .setAlarmSnoozeUntil(value: let value):
        if let value = value {
            state.alarmSnoozeUntil = value

            // stop sounds
            NotificationService.shared.stopSound()
        } else {
            state.alarmSnoozeUntil = nil
        }
        
    case .setChartShowLines(value: let value):
        state.chartShowLines = value

    case .setGlucoseUnit(value: let value):
        state.glucoseUnit = value

    case .setNightscoutHost(host: let host):
        state.nightscoutHost = host

    case .setNightscoutSecret(apiSecret: let apiSecret):
        state.nightscoutApiSecret = apiSecret

    case .setNightscoutUpload(enabled: let enabled):
        state.nightscoutUpload = enabled

    case .setSensor(value: let value):
        state.sensor = value

    case .setSensorAge(sensorAge: let sensorAge):
        guard state.sensor != nil else {
            return
        }

        state.sensor!.age = sensorAge

    case .setSensorConnectionState(connectionState: let connectionState):
        state.connectionState = connectionState

        if resetableStates.contains(connectionState) {
            state.connectionError = nil
            state.connectionErrorTimestamp = nil
        }

    case .setSensorError(errorMessage: let errorMessage, errorTimestamp: let errorTimestamp):
        state.connectionError = errorMessage
        state.connectionErrorTimestamp = errorTimestamp

    case .setSensorGlucose(glucose: let glucose):
        state.missedReadings = 0
        state.glucoseValues.append(glucose)

        if let numberOfGlucoseValues = AppConfig.NumberOfGlucoseValues {
            let toMany = state.glucoseValues.count - numberOfGlucoseValues
            if toMany > 0 {
                for _ in 1 ... toMany {
                    state.glucoseValues.removeFirst()
                }
            }
        }
        
    case .setSensorGlucoseValues(values: let values):
        state.missedReadings = 0
        state.glucoseValues.append(contentsOf: values)

    case .setSensorMissedReading:
        state.missedReadings += 1

    case .setSensorReadings:
        break
        
    case .selectView(value: let value):
        state.selectedView = value
    }

    if let alarmSnoozeUntil = state.alarmSnoozeUntil, Date() > alarmSnoozeUntil {
        state.alarmSnoozeUntil = nil
    }
}

// MARK: - fileprivate

private var resetableStates: Set<SensorConnectionState> = [.connected, .powerOff, .scanning]
private var disconnectedStates: Set<SensorConnectionState> = [.disconnected, .scanning]
