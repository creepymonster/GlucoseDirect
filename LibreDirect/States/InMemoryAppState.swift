//
//  InMemoryAppState.swift
//  LibreDirect
//

import Combine
import Foundation

// MARK: - PreviewAppState

struct InMemoryAppState: AppState {
    var alarmHigh = 160
    var alarmLow = 80
    var alarmSnoozeUntil: Date? = nil
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
    var selectedCalendarTarget: String? = nil
    var selectedConnection: SensorConnection? = nil
    var selectedConnectionId: String? = nil
    var selectedView: Int = 1
    var sensor: Sensor?
    var targetValue: Int = 100
    var transmitter: Transmitter? = nil
}
