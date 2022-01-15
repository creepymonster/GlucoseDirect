//
//  DefaultAppReducer.swift
//  LibreDirect
//

import Combine
import Foundation

// MARK: - appReducer

func appReducer(state: inout AppState, action: AppAction) {
    switch action {
    case .addCalibration(glucoseValue: let glucoseValue):
        guard state.sensor != nil else {
            AppLog.info("Guard: state.sensor is nil")
            break
        }
        
        guard let factoryCalibratedGlucoseValue = state.currentGlucose?.initialGlucoseValue else {
            AppLog.info("Guard: state.currentGlucose.initialGlucoseValue is nil")
            break
        }
        
        state.customCalibration.append(CustomCalibration(x: Double(factoryCalibratedGlucoseValue), y: Double(glucoseValue)))
        
    case .addGlucoseValues(glucoseValues: let addedGlucoseValues):
        if !addedGlucoseValues.isEmpty {
            var glucoseValues = state.glucoseValues + addedGlucoseValues
            
            let overLimit = glucoseValues.count - AppConfig.numberOfGlucoseValues
            if overLimit > 0 {
                glucoseValues = Array(glucoseValues.dropFirst(overLimit))
            }
            
            state.missedReadings = 0
            state.glucoseValues = glucoseValues
        }
        
    case .addMissedReading:
        state.missedReadings += 1
        
    case .addSensorReadings:
        break
        
    case .clearCalibrations:
        guard state.sensor != nil else {
            AppLog.info("Guard: state.sensor is nil")
            break
        }
        
        state.customCalibration = []
        
    case .clearGlucoseValues:
        state.glucoseValues = []
        
    case .connectSensor:
        break
        
    case .deleteLogs:
        break

    case .disconnectSensor:
        break

    case .pairSensor:
        break
        
    case .scanSensor:
        break
        
    case .registerConnectionInfo(infos: let infos):
        state.connectionInfos.append(contentsOf: infos)
        
    case .removeCalibration(id: let id):
        guard state.sensor != nil else {
            AppLog.info("Guard: state.sensor is nil")
            break
        }
        
        state.customCalibration = state.customCalibration.filter { item in
            item.id != id
        }
        
    case .removeGlucose(id: let id):
        state.glucoseValues = state.glucoseValues.filter { item in
            item.id != id
        }
        
    case .resetSensor:
        state.isPaired = false
        state.sensor = nil
        state.customCalibration = []
        state.connectionError = nil
        state.connectionErrorIsCritical = false
        state.connectionErrorTimestamp = nil
        
    case .selectCalendarTarget(id: let id):
        state.selectedCalendarTarget = id
        
    case .selectConnection(id: let id, connection: let connection):
        if id != state.selectedConnectionId || state.selectedConnection == nil {
            state.selectedConnectionId = id
            state.selectedConnection = connection
        }
        
    case .selectConnectionId(id: _):
        state.isPaired = false
        state.sensor = nil
        state.customCalibration = []
        state.transmitter = nil
        state.connectionError = nil
        state.connectionErrorIsCritical = false
        state.connectionErrorTimestamp = nil
        
    case .selectView(viewTag: let viewTag):
        state.selectedView = viewTag
        
    case .sendLogs:
        break
        
    case .setAlarmHigh(upperLimit: let upperLimit):
        state.alarmHigh = upperLimit

    case .setAlarmLow(lowerLimit: let lowerLimit):
        state.alarmLow = lowerLimit

    case .setAlarmSnoozeUntil(untilDate: let untilDate, autosnooze: _):
        if let untilDate = untilDate {
            state.alarmSnoozeUntil = untilDate
        } else {
            state.alarmSnoozeUntil = nil
        }
        
    case .setCalendarExport(enabled: let enabled):
        state.calendarExport = enabled
        
    case .setChartShowLines(enabled: let enabled):
        state.chartShowLines = enabled
        
    case .setChartZoomLevel(level: let level):
        state.chartZoomLevel = level
        
    case .setConnectionAlarmSound(sound: let sound):
        state.connectionAlarmSound = sound
        
    case .setConnectionError(errorMessage: let errorMessage, errorTimestamp: let errorTimestamp, errorIsCritical: let errorIsCritical):
        state.connectionError = errorMessage
        state.connectionErrorTimestamp = errorTimestamp
        state.connectionErrorIsCritical = errorIsCritical
        
    case .setConnectionState(connectionState: let connectionState):
        state.connectionState = connectionState

        if resetableStates.contains(connectionState) {
            state.connectionError = nil
            state.connectionErrorIsCritical = false
            state.connectionErrorTimestamp = nil
        }
        
    case .setExpiringAlarmSound(sound: let sound):
        state.expiringAlarmSound = sound
               
    case .setGlucoseBadge(enabled: let enabled):
        state.glucoseBadge = enabled
        
    case .setGlucoseUnit(unit: let unit):
        state.glucoseUnit = unit
        
    case .setHighGlucoseAlarmSound(sound: let sound):
        state.highGlucoseAlarmSound = sound
        
    case .setInternalHttpServer(enabled: let enabled):
        state.internalHttpServer = enabled
        
    case .setIgnoreMute(enabled: let enabled):
        state.ignoreMute = enabled
        
    case .setLowGlucoseAlarmSound(sound: let sound):
        state.lowGlucoseAlarmSound = sound

    case .setNightscoutSecret(apiSecret: let apiSecret):
        state.nightscoutApiSecret = apiSecret

    case .setNightscoutUpload(enabled: let enabled):
        state.nightscoutUpload = enabled
        
    case .setNightscoutUrl(url: let url):
        state.nightscoutUrl = url
        
    case .setReadGlucose(enabled: let enabled):
        state.readGlucose = enabled
        
    case .setSensor(sensor: let sensor, wasPaired: let wasPaired):
        let isModifiedSensor = state.isScanable && !wasPaired && (state.sensor == nil || state.sensor?.serial != sensor.serial)
        
        if let sensorSerial = state.sensor?.serial, sensorSerial != sensor.serial {
            state.customCalibration = []
        }
        
        state.sensor = sensor
        state.connectionError = nil
        state.connectionErrorIsCritical = false
        state.connectionErrorTimestamp = nil
        
        if isModifiedSensor {
            state.isPaired = false
        } else if wasPaired {
            state.isPaired = true
        }
        
    case .setSensorInterval(interval: let interval):
        state.sensorInterval = interval

    case .setSensorState(sensorAge: let sensorAge, sensorState: let sensorState):
        guard state.sensor != nil else {
            AppLog.info("Guard: state.sensor is nil")
            break
        }
        
        state.sensor!.age = sensorAge
        
        if let sensorState = sensorState {
            state.sensor!.state = sensorState
        }
        
        if state.sensor!.startTimestamp == nil {
            state.sensor!.startTimestamp = Date() - Double(sensorAge) * 60
        }

    case .setTransmitter(transmitter: let transmitter):
        state.isPaired = true
        state.transmitter = transmitter
        
    case .startup:
        break
    }

    if let alarmSnoozeUntil = state.alarmSnoozeUntil, Date() > alarmSnoozeUntil {
        state.alarmSnoozeUntil = nil
    }
}

// MARK: - private

private var resetableStates: Set<SensorConnectionState> = [.connected, .powerOff, .scanning]
private var disconnectedStates: Set<SensorConnectionState> = [.disconnected, .scanning]
