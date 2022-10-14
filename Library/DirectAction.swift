//
//  DirectAction.swift
//  GlucoseDirect
//

import Foundation
import SwiftUI
import OSLog

enum DirectAction {
    case addBloodGlucose(glucoseValues: [BloodGlucose])
    case addCalibration(bloodGlucoseValue: Int)
    case addSensorError(errorValues: [SensorError])
    case addSensorGlucose(glucoseValues: [SensorGlucose])
    case addSensorReadings(readings: [SensorReading])
    case bellmanTestAlarm
    case clearBloodGlucoseValues
    case clearCalibrations
    case clearSensorErrorValues
    case clearSensorGlucoseValues
    case connectConnection
    case deleteBloodGlucose(glucose: BloodGlucose)
    case deleteCalibration(calibration: CustomCalibration)
    case deleteLogs
    case deleteSensorError(error: SensorError)
    case deleteSensorGlucose(glucose: SensorGlucose)
    case disconnectConnection
    case loadBloodGlucoseValues
    case loadSensorErrorValues
    case loadSensorGlucoseValues
    case loadSensorGlucoseStatistics
    case pairConnection
    case registerConnectionInfo(infos: [SensorConnectionInfo])
    case requestAppleCalendarAccess(enabled: Bool)
    case requestAppleHealthAccess(enabled: Bool)
    case resetSensor
    case resetError
    case selectCalendarTarget(id: String?)
    case selectConnection(id: String, connection: SensorConnectionProtocol)
    case selectConnectionID(id: String)
    case selectView(viewTag: Int)
    case sendLogs
    case sendDatabase
    case setIgnoreMute(enabled: Bool)
    case setAlarmHigh(upperLimit: Int)
    case setAlarmLow(lowerLimit: Int)
    case setAlarmSnoozeUntil(untilDate: Date?, autosnooze: Bool = false)
    case setAppleCalendarExport(enabled: Bool)
    case setAppleHealthExport(enabled: Bool)
    case setAppState(appState: ScenePhase)
    case setBellmanConnectionState(connectionState: BellmanConnectionState)
    case setBellmanNotification(enabled: Bool)
    case setBloodGlucoseHistory(glucoseHistory: [BloodGlucose])
    case setBloodGlucoseValues(glucoseValues: [BloodGlucose])
    case setChartShowLines(enabled: Bool)
    case setChartZoomLevel(level: Int)
    case setConnectionAlarmSound(sound: NotificationSound)
    case setConnectionError(errorMessage: String, errorTimestamp: Date)
    case setConnectionPaired(isPaired: Bool)
    case setConnectionPeripheralUUID(peripheralUUID: String?)
    case setConnectionState(connectionState: SensorConnectionState)
    case setExpiringAlarmSound(sound: NotificationSound)
    case setNormalGlucoseNotification(enabled: Bool)
    case setAlarmGlucoseNotification(enabled: Bool)
    case setGlucoseLiveActivity(enabled: Bool)
    case setGlucoseUnit(unit: GlucoseUnit)
    case setHighGlucoseAlarmSound(sound: NotificationSound)
    case setLowGlucoseAlarmSound(sound: NotificationSound)
    case setNightscoutSecret(apiSecret: String)
    case setNightscoutUpload(enabled: Bool)
    case setNightscoutURL(url: String)
    case setPreventScreenLock(enabled: Bool)
    case setReadGlucose(enabled: Bool)
    case setSensor(sensor: Sensor, keepDevice: Bool = false)
    case setSensorErrorValues(errorValues: [SensorError])
    case setSensorGlucoseHistory(glucoseHistory: [SensorGlucose])
    case setSensorGlucoseValues(glucoseValues: [SensorGlucose])
    case setSensorInterval(interval: Int)
    case setSensorState(sensorAge: Int, sensorState: SensorState?)
    case setShowAnnotations(showAnnotations: Bool)
    case setGlucoseStatistics(statistics: GlucoseStatistics)
    case setTransmitter(transmitter: Transmitter)
    case startup
    case shutdown
    
    case debugAlarm
    case debugNotification
}
