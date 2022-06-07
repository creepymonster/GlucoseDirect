//
//  AppAction.swift
//  GlucoseDirect
//

import Foundation
import OSLog

enum AppAction {
    case addCalibration(glucoseValue: Int)
    case addGlucoseValues(glucoseValues: [Glucose])
    case addMissedReading
    case addSensorReadings(sensorSerial: String, readings: [SensorReading])
    case bellmanTestAlarm
    case clearCalibrations
    case clearGlucoseValues
    case connectConnection
    case deleteLogs
    case disconnectConnection
    case pairConnection
    case registerConnectionInfo(infos: [SensorConnectionInfo])
    case removeCalibration(id: UUID)
    case removeGlucose(id: UUID)
    case resetSensor
    case selectCalendarTarget(id: String?)
    case selectConnection(id: String, connection: SensorBLEConnection)
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
    case setChartShowLines(enabled: Bool)
    case setChartZoomLevel(level: Int)
    case setConnectionAlarmSound(sound: NotificationSound)
    case setConnectionError(errorMessage: String, errorTimestamp: Date, errorIsCritical: Bool)
    case setConnectionState(connectionState: SensorConnectionState)
    case setConnectionPaired(isPaired: Bool)
    case setConnectionPeripheralUUID(peripheralUUID: String?)
    case setExpiringAlarmSound(sound: NotificationSound)
    case setGlucoseNotification(enabled: Bool)
    case setGlucoseUnit(unit: GlucoseUnit)
    case setHighGlucoseAlarmSound(sound: NotificationSound)
    case setIgnoreMute(enabled: Bool)
    case setLowGlucoseAlarmSound(sound: NotificationSound)
    case setNightscoutSecret(apiSecret: String)
    case setNightscoutUpload(enabled: Bool)
    case setNightscoutURL(url: String)
    case setReadGlucose(enabled: Bool)
    case setSensor(sensor: Sensor, keepDevice: Bool = false)
    case setSensorInterval(interval: Int)
    case setSensorState(sensorAge: Int, sensorState: SensorState?)
    case setTransmitter(transmitter: Transmitter)
    case startup
}
