//
//  DefaultAppReducer.swift
//  LibreDirect
//

import Combine
import Foundation

func appReducer(state: inout AppState, action: AppAction) {
    dispatchPrecondition(condition: .onQueue(.main))

    switch action {
    case .addCalibration(glucoseValue: let glucoseValue):
        if let factoryCalibratedGlucoseValue = state.currentGlucose?.initialGlucoseValue {
            let calibration = CustomCalibration(x: Double(factoryCalibratedGlucoseValue), y: Double(glucoseValue))
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

    case .selectView(viewTag: let viewTag):
        state.selectedView = viewTag

    case .setGlucoseAlarm(enabled: let enabled):
        state.glucoseAlarm = enabled

    case .setExpiringAlarm(enabled: let enabled):
        state.expiringAlarm = enabled

    case .setConnectionAlarm(enabled: let enabled):
        state.connectionAlarm = enabled

    case .setAlarmHigh(upperLimit: let upperLimit):
        state.alarmHigh = upperLimit

    case .setAlarmLow(lowerLimit: let lowerLimit):
        state.alarmLow = lowerLimit

    case .setAlarmSnoozeUntil(untilDate: let untilDate):
        if let untilDate = untilDate {
            state.alarmSnoozeUntil = untilDate

            // stop sounds
            NotificationService.shared.stopSound()
        } else {
            state.alarmSnoozeUntil = nil
        }

    case .setChartShowLines(enabled: let enabled):
        state.chartShowLines = enabled

    case .setGlucoseBadge(enabled: let enabled):
        state.glucoseBadge = enabled

    case .setGlucoseUnit(unit: let unit):
        state.glucoseUnit = unit

    case .setNightscoutHost(host: let host):
        state.nightscoutHost = host

    case .setNightscoutSecret(apiSecret: let apiSecret):
        state.nightscoutApiSecret = apiSecret

    case .setNightscoutUpload(enabled: let enabled):
        state.nightscoutUpload = enabled

    case .setSensor(sensor: let sensor):
        state.sensor = sensor

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

    case .addGlucoseValues(glucoseValues: let glucoseValues):
        if !glucoseValues.isEmpty {
            state.missedReadings = 0
            state.glucoseValues.append(contentsOf: glucoseValues)
        }

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
