//
//  PreviewAppState.swift
//  LibreDirect
//

import Combine
import Foundation

// MARK: - PreviewAppState

struct PreviewAppState: AppState {
    var alarmHigh: Int = 160
    var alarmLow: Int = 80
    var alarmSnoozeUntil: Date?
    var calendarExport = false
    var chartShowLines = false
    var connectionAlarm = true
    var connectionError: String? = "Timeout"
    var connectionErrorIsCritical = false
    var connectionErrorTimestamp: Date? = Date()
    var connectionInfos: [SensorConnectionInfo] = []
    var connectionState: SensorConnectionState = .connected
    var expiringAlarm = true
    var glucoseAlarm = true
    var glucoseBadge = true
    var glucoseUnit = GlucoseUnit.mgdL
    var glucoseValues: [Glucose] = []
    var missedReadings: Int = 0
    var nightscoutApiSecret: String = ""
    var nightscoutHost: String = ""
    var nightscoutUpload: Bool = false
    var selectedCalendarTarget: String?
    var selectedConnection: SensorConnection?
    var selectedConnectionId: String?
    var selectedView: Int = 1
    var sensor: Sensor? = Sensor(uuid: Data(hexString: "e9ad9b6c79bd93aa")!, patchInfo: Data(hexString: "448cd1")!, factoryCalibration: FactoryCalibration(i1: 1, i2: 2, i3: 4, i4: 8, i5: 16, i6: 32), customCalibration: [], family: .unknown, type: .virtual, region: .european, serial: "OBIR2PO", state: .ready, age: 120, lifetime: 24 * 60)
    var targetValue: Int = 100
    var transmitter: Transmitter?
}
