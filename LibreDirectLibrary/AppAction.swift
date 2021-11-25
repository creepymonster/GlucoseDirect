//
//  AppAction.swift
//  LibreDirect
//

import Foundation

enum AppAction {
    case addCalibration(bloodGlucose: Int)
    case clearCalibrations
    case removeCalibration(id: UUID)

    case connectSensor
    case disconnectSensor
    case pairSensor
    case resetSensor

    case selectView(value: Int)
    case setAlarmHigh(value: Int)
    case setAlarmLow(value: Int)
    case setAlarmSnoozeUntil(value: Date?)
    case setChartShowLines(value: Bool)
    case setGlucoseUnit(value: GlucoseUnit)
    case setNightscoutHost(host: String)
    case setNightscoutSecret(apiSecret: String)
    case setNightscoutUpload(enabled: Bool)

    case setSensor(value: Sensor)
    case setSensorConnectionState(connectionState: SensorConnectionState)
    case setSensorError(errorMessage: String, errorTimestamp: Date)
    case addGlucose(glucose: Glucose)
    case addGlucoseValues(values: [Glucose])
    case addMissedReading
    case addSensorReadings(nextReading: SensorReading, trendReadings: [SensorReading], historyReadings: [SensorReading])
    case setSensorState(sensorAge: Int, sensorState: SensorState)
    case removeGlucose(id: UUID)
    case clearGlucoseValues
}
