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
    var connectionError: String? = "Timeout"
    var connectionErrorIsCritical = false
    var connectionErrorTimestamp: Date? = Date()
    var connectionInfos: [SensorConnectionInfo] = []
    var connectionState: SensorConnectionState = .disconnected
    var expiringAlarm = true
    var glucoseAlarm = true
    var glucoseBadge = true
    var glucoseUnit: GlucoseUnit = .mgdL
    var glucoseValues: [Glucose] = []
    var missedReadings: Int = 0
    var nightscoutApiSecret: String = ""
    var nightscoutHost: String = ""
    var nightscoutUpload: Bool = false
    var selectedCalendarTarget: String?
    var selectedConnection: SensorConnection?
    var selectedConnectionId: String?
    var selectedView: Int = 1
    var sensor: Sensor?
    var targetValue: Int = 100
    var transmitter: Transmitter?
}
