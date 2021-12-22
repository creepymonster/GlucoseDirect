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
    var connectionAlarm = true
    var connectionError: String?
    var connectionErrorIsCritical = false
    var connectionErrorTimestamp: Date? = Date()
    var connectionInfos: [SensorConnectionInfo] = []
    var connectionState: SensorConnectionState = .disconnected
    var expiringAlarm = true
    var glucoseAlarm = true
    var glucoseBadge = true
    var glucoseUnit: GlucoseUnit = .mgdL
    var glucoseValues: [Glucose] = []
    var missedReadings = 0
    var nightscoutApiSecret = ""
    var nightscoutUrl = ""
    var nightscoutUpload = false
    var readGlucose = false
    var selectedCalendarTarget: String?
    var selectedConnection: SensorConnection?
    var selectedConnectionId: String?
    var selectedView = 1
    var sensor: Sensor?
    var targetValue = 100
    var transmitter: Transmitter?
}
