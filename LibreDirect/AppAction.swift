//
//  AppAction.swift
//  LibreDirect
//

import Foundation

enum AppAction {
    case addCalibration(glucoseValue: Int)
    case addGlucose(glucose: Glucose)
    case addGlucoseValues(glucoseValues: [Glucose])
    case addMissedReading
    case addSensorReadings(nextReading: SensorReading, trendReadings: [SensorReading], historyReadings: [SensorReading])
    
    case clearCalibrations
    case clearGlucoseValues
    
    case connectSensor
    case disconnectSensor
    case pairSensor
    
    case registerConnectionInfo(infos: [SensorConnectionInfo])
    
    case removeCalibration(id: UUID)
    case removeGlucose(id: UUID)
    
    case resetSensor
    case resetTransmitter
    
    case selectConnection(id: String, connection: SensorConnection)
    case selectConnectionId(id: String)
    case selectView(viewTag: Int)
    
    case setAlarmHigh(upperLimit: Int)
    case setAlarmLow(lowerLimit: Int)
    case setAlarmSnoozeUntil(untilDate: Date?)
    case setChartShowLines(enabled: Bool)
    case setConnectionAlarm(enabled: Bool)
    case setConnectionError(errorMessage: String, errorTimestamp: Date)
    case setConnectionState(connectionState: SensorConnectionState)
    case setExpiringAlarm(enabled: Bool)
    case setGlucoseAlarm(enabled: Bool)
    case setGlucoseBadge(enabled: Bool)
    case setGlucoseUnit(unit: GlucoseUnit)
    case setNightscoutHost(host: String)
    case setNightscoutSecret(apiSecret: String)
    case setNightscoutUpload(enabled: Bool)
    case setSensor(sensor: Sensor)
    case setSensorState(sensorAge: Int, sensorState: SensorState?)
    case setTransmitter(transmitter: Transmitter)
    
    case startup
}
