//
//  AppAction.swift
//  LibreDirect
//

import Foundation
import OSLog

enum AppAction {
    case addCalibration(glucoseValue: Int)
    case addGlucoseValues(glucoseValues: [Glucose])
    case addMissedReading
    case addSensorReadings(sensorSerial: String, trendReadings: [SensorReading], historyReadings: [SensorReading])
    case clearCalibrations
    case clearGlucoseValues
    case connectSensor
    case deleteLogs
    case disconnectSensor
    case pairSensor
    case scanSensor
    case registerConnectionInfo(infos: [SensorConnectionInfo])
    case removeCalibration(id: UUID)
    case removeGlucose(id: UUID)
    case resetSensor
    case selectCalendarTarget(id: String?)
    case selectConnection(id: String, connection: SensorBLEConnection)
    case selectConnectionId(id: String)
    case selectView(viewTag: Int)
    case sendLogs
    case setAlarmHigh(upperLimit: Int)
    case setAlarmLow(lowerLimit: Int)
    case setAlarmSnoozeUntil(untilDate: Date?, autosnooze: Bool = false)
    case setCalendarExport(enabled: Bool)
    case setChartShowLines(enabled: Bool)
    case setChartZoomLevel(level: Int)
    case setConnectionAlarmSound(sound: NotificationSound)
    case setConnectionError(errorMessage: String, errorTimestamp: Date, errorIsCritical: Bool)
    case setConnectionState(connectionState: SensorConnectionState)
    case setExpiringAlarmSound(sound: NotificationSound)
    case setGlucoseBadge(enabled: Bool)
    case setGlucoseUnit(unit: GlucoseUnit)
    case setHighGlucoseAlarmSound(sound: NotificationSound)
    case setInternalHttpServer(enabled: Bool)
    case setIgnoreMute(enabled: Bool)
    case setLowGlucoseAlarmSound(sound: NotificationSound)
    case setNightscoutSecret(apiSecret: String)
    case setNightscoutUpload(enabled: Bool)
    case setNightscoutUrl(url: String)
    case setReadGlucose(enabled: Bool)
    case setSensor(sensor: Sensor, wasCoupled: Bool = false)
    case setSensorState(sensorAge: Int, sensorState: SensorState?)
    case setTransmitter(transmitter: Transmitter)
    case startup
}
