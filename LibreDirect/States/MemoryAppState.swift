//
//  InMemoryAppState.swift
//  LibreDirect
//

import Combine
import Foundation

// MARK: - InMemoryAppState

struct MemoryAppState: AppState {
    var alarmHigh = 160
    var alarmLow = 80
    var alarmSnoozeUntil: Date?
    var calendarExport = false
    var chartShowLines = false
    var chartZoomLevel = 1
    var connectionAlarmSound: NotificationSound = .alarm
    var connectionError: String?
    var connectionErrorIsCritical = false
    var connectionErrorTimestamp: Date? = Date()
    var connectionInfos: [SensorConnectionInfo] = []
    var connectionState: SensorConnectionState = .disconnected
    var customCalibration: [CustomCalibration] = []
    var expiringAlarmSound: NotificationSound = .expiring
    var glucoseBadge = true
    var glucoseUnit: GlucoseUnit = .mgdL
    var glucoseValues: [Glucose] = []
    var highGlucoseAlarmSound: NotificationSound = .alarm
    var internalHttpServer = false
    var isPaired = false
    var ignoreMute = false
    var lowGlucoseAlarmSound: NotificationSound = .alarm
    var missedReadings = 0
    var nightscoutApiSecret = ""
    var nightscoutUpload = false
    var nightscoutUrl = ""
    var readGlucose = false
    var selectedCalendarTarget: String?
    var selectedConnection: SensorBLEConnection?
    var selectedConnectionId: String?
    var selectedView = 1
    var sensor: Sensor?
    var targetValue = 100
    var transmitter: Transmitter?
}
