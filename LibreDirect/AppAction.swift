//
//  AppAction.swift
//  LibreDirect
//

import Foundation

enum AppAction {
    case addCalibration(glucoseValue: Int)
    case clearCalibrations
    case removeCalibration(id: UUID)

    case connectSensor
    case disconnectSensor
    case pairSensor
    case resetSensor

    case selectView(viewTag: Int)
    case setGlucoseAlarm(enabled: Bool)
    case setExpiringAlarm(enabled: Bool)
    case setConnectionAlarm(enabled: Bool)
    case setGlucoseBadge(enabled: Bool)
    
    case setAlarmHigh(upperLimit: Int)
    case setAlarmLow(lowerLimit: Int)
    case setAlarmSnoozeUntil(untilDate: Date?)
    case setChartShowLines(enabled: Bool)
    case setGlucoseUnit(unit: GlucoseUnit)
    case setNightscoutHost(host: String)
    case setNightscoutSecret(apiSecret: String)
    case setNightscoutUpload(enabled: Bool)

    case setSensor(sensor: Sensor)
    case setSensorConnectionState(connectionState: SensorConnectionState)
    case setSensorError(errorMessage: String, errorTimestamp: Date)
    case addGlucose(glucose: Glucose)
    case addGlucoseValues(glucoseValues: [Glucose])
    case addMissedReading
    case addSensorReadings(nextReading: SensorReading, trendReadings: [SensorReading], historyReadings: [SensorReading])
    case setSensorState(sensorAge: Int, sensorState: SensorState)
    case removeGlucose(id: UUID)
    case clearGlucoseValues
}
