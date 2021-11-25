//
//  DefaultAppReducer.swift
//  LibreDirect
//

import Combine
import Foundation

func appReducer(state: inout AppState, action: AppAction) {
    dispatchPrecondition(condition: .onQueue(.main))

    switch action {
    case .addCalibration(bloodGlucose: let bloodGlucose):
        if let factoryCalibratedGlucoseValue = state.currentGlucose?.initialGlucoseValue {
            let calibration = CustomCalibration(x: Double(factoryCalibratedGlucoseValue), y: Double(bloodGlucose))
            state.sensor?.customCalibration.append(calibration)
        }

    case .clearCalibrations:
        state.sensor?.customCalibration = []

    case .removeCalibration(id: let id):
        if state.sensor != nil {
            state.sensor!.customCalibration = state.sensor!.customCalibration.filter { item in
                item.id != id
            }
        }

    case .connectSensor:
        break

    case .disconnectSensor:
        break

    case .pairSensor:
        break

    case .resetSensor:
        state.sensor = nil
        state.connectionError = nil

    case .selectView(value: let value):
        state.selectedView = value

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

    case .setSensorConnectionState(connectionState: let connectionState):
        state.connectionState = connectionState

        if resetableStates.contains(connectionState) {
            state.connectionError = nil
            state.connectionErrorTimestamp = nil
        }

    case .setSensorError(errorMessage: let errorMessage, errorTimestamp: let errorTimestamp):
        state.connectionError = errorMessage
        state.connectionErrorTimestamp = errorTimestamp

    case .addGlucose(glucose: let glucose):
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

    case .addGlucoseValues(values: let values):
        state.missedReadings = 0
        state.glucoseValues.append(contentsOf: values)

    case .addMissedReading:
        state.missedReadings += 1

    case .addSensorReadings:
        break

    case .setSensorState(sensorAge: let sensorAge, sensorState: let sensorState):
        guard state.sensor != nil else {
            return
        }

        state.sensor!.age = sensorAge
        state.sensor!.state = sensorState

    case .removeGlucose(id: let id):
        state.glucoseValues = state.glucoseValues.filter { item in
            item.id != id
        }

    case .clearGlucoseValues:
        state.glucoseValues = []
    }

    if let alarmSnoozeUntil = state.alarmSnoozeUntil, Date() > alarmSnoozeUntil {
        state.alarmSnoozeUntil = nil
    }
}

// MARK: - fileprivate

private var resetableStates: Set<SensorConnectionState> = [.connected, .powerOff, .scanning]
private var disconnectedStates: Set<SensorConnectionState> = [.disconnected, .scanning]
