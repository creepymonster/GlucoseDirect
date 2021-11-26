//
//  InMemoryAppState.swift
//  LibreDirect
//

import Combine
import Foundation

// MARK: - PreviewAppState

struct InMemoryAppState: AppState {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    var alarm = false
    var alarmHigh = 160
    var alarmLow = 80
    var alarmSnoozeUntil: Date?
    var chartShowLines = false
    var connectionError: String? = "Timeout"
    var connectionErrorTimestamp: Date? = Date()
    var connectionState: SensorConnectionState = .disconnected
    var glucoseUnit: GlucoseUnit = .mgdL
    var glucoseValues: [Glucose] = []
    var missedReadings: Int = 0
    var nightscoutApiSecret: String = ""
    var nightscoutHost: String = ""
    var nightscoutUpload: Bool = false
    var selectedView: Int = 1
    var sensor: Sensor?
    var targetValue: Int = 100
}
