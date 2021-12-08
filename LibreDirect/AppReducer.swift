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
        guard let sensor = state.sensor else {
            break
        }
        
        guard let factoryCalibratedGlucoseValue = state.currentGlucose?.initialGlucoseValue else {
            break
        }
        
        var calibration = sensor.customCalibration
        calibration.append(CustomCalibration(x: Double(factoryCalibratedGlucoseValue), y: Double(glucoseValue)))
        
        sensor.customCalibration = calibration
        state.sensor = sensor
        
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
        
    case .clearCalibrations:
        if let sensor = state.sensor {
            sensor.customCalibration = []
            state.sensor = sensor
        }
        
    case .clearGlucoseValues:
        state.glucoseValues = []
        
    case .connectSensor:
        break

    case .disconnectSensor:
        break

    case .pairSensor:
        break
        
    case .registerConnectionInfo(infos: let infos):
        state.connectionInfos.append(contentsOf: infos)
        
    case .removeCalibration(id: let id):
        if let sensor = state.sensor {
            sensor.customCalibration = sensor.customCalibration.filter { item in
                item.id != id
            }
            state.sensor = sensor
        }
        
    case .removeGlucose(id: let id):
        state.glucoseValues = state.glucoseValues.filter { item in
            item.id != id
        }
        
    case .resetSensor:
        state.sensor = nil
        state.connectionError = nil
        
    case .resetTransmitter:
        state.transmitter = nil
        
    case .selectCalendarTarget(id: let id):
        state.selectedCalendarTarget = id
        
    case .selectConnection(id: let id, connection: let connection):
        if id != state.selectedConnectionId || state.selectedConnection == nil {
            state.selectedConnectionId = id
            state.selectedConnection = connection
        }
        
    case .selectConnectionId(id: _):
        state.sensor = nil
        state.transmitter = nil
        state.connectionError = nil
        
    case .selectView(viewTag: let viewTag):
        state.selectedView = viewTag
        
    case .setAlarmHigh(upperLimit: let upperLimit):
        state.alarmHigh = upperLimit

    case .setAlarmLow(lowerLimit: let lowerLimit):
        state.alarmLow = lowerLimit
        
    case .setCalendarExport(enabled: let enabled):
        state.calendarExport = enabled
        
    case .setAlarmSnoozeUntil(untilDate: let untilDate):
        if let untilDate = untilDate {
            state.alarmSnoozeUntil = untilDate
        } else {
            state.alarmSnoozeUntil = nil
        }
        
    case .setChartShowLines(enabled: let enabled):
        state.chartShowLines = enabled
        
    case .setConnectionAlarm(enabled: let enabled):
        state.connectionAlarm = enabled
        
    case .setConnectionError(errorMessage: let errorMessage, errorTimestamp: let errorTimestamp, errorIsCritical: let errorIsCritical):
        state.connectionError = errorMessage
        state.connectionErrorTimestamp = errorTimestamp
        state.connectionErrorIsCritical = errorIsCritical
        
    case .setConnectionState(connectionState: let connectionState):
        state.connectionState = connectionState

        if resetableStates.contains(connectionState) {
            state.connectionError = nil
            state.connectionErrorTimestamp = nil
        }
        
    case .setExpiringAlarm(enabled: let enabled):
        state.expiringAlarm = enabled
        
    case .setGlucoseAlarm(enabled: let enabled):
        state.glucoseAlarm = enabled
        
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

    case .setSensorState(sensorAge: let sensorAge, sensorState: let sensorState):
        guard let sensor = state.sensor else {
            break
        }

        sensor.age = sensorAge
        if let sensorState = sensorState {
            sensor.state = sensorState
        }

        state.sensor = sensor

    case .setTransmitter(transmitter: let transmitter):
        state.transmitter = transmitter
        
    case .startup:
        break
    }

    if let alarmSnoozeUntil = state.alarmSnoozeUntil, Date() > alarmSnoozeUntil {
        state.alarmSnoozeUntil = nil
    }
}

// MARK: - fileprivate

private var resetableStates: Set<SensorConnectionState> = [.connected, .powerOff, .scanning]
private var disconnectedStates: Set<SensorConnectionState> = [.disconnected, .scanning]
