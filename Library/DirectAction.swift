//
//  DirectAction.swift
//  GlucoseDirect
//

import Foundation
import OSLog

enum DirectAction {
    case addBloodGlucose(glucoseValues: [BloodGlucose])
    case addCalibration(bloodGlucoseValue: Int)
    case addSensorError(errorValues: [SensorError])
    case addSensorGlucose(glucoseValues: [SensorGlucose])
    case addSensorReadings(sensorSerial: String, readings: [SensorReading])
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
    case pairConnection
    case registerConnectionInfo(infos: [SensorConnectionInfo])
    case requestAppleCalendarAccess(enabled: Bool)
    case requestAppleHealthAccess(enabled: Bool)
    case resetSensor
    case selectCalendarTarget(id: String?)
    case selectConnection(id: String, connection: SensorConnectionProtocol)
    case selectConnectionID(id: String)
    case selectView(viewTag: Int)
    case sendLogs
    case setAlarmHigh(upperLimit: Int)
    case setAlarmLow(lowerLimit: Int)
    case setAlarmSnoozeUntil(untilDate: Date?, autosnooze: Bool = false)
    case setAppleCalendarExport(enabled: Bool)
    case setAppleHealthExport(enabled: Bool)
    case setBellmanConnectionState(connectionState: BellmanConnectionState)
    case setBellmanNotification(enabled: Bool)
    case setBloodGlucoseHistory(glucoseHistory: [BloodGlucose])
    case setBloodGlucoseValues(glucoseValues: [BloodGlucose])
    case setChartShowLines(enabled: Bool)
    case setChartZoomLevel(level: Int)
    case setConnectionAlarmSound(sound: NotificationSound)
    case setConnectionError(errorMessage: String, errorTimestamp: Date, errorIsCritical: Bool)
    case setConnectionPaired(isPaired: Bool)
    case setConnectionPeripheralUUID(peripheralUUID: String?)
    case setConnectionState(connectionState: SensorConnectionState)
    case setExpiringAlarmSound(sound: NotificationSound)
    case setGlucoseNotification(enabled: Bool)
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
    case setTransmitter(transmitter: Transmitter)
    case startup
    case shutdown
    
    case debugAlarm
    case debugNotification
}
