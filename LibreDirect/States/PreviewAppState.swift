//
//  PreviewAppState.swift
//  LibreDirect
//

import Combine
import Foundation

// MARK: - PreviewAppState

struct PreviewAppState: AppState {
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
    var connectionState: SensorConnectionState = .connected
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
    var sensor: Sensor? = Sensor(uuid: Data(hexString: "e9ad9b6c79bd93aa")!, patchInfo: Data(hexString: "448cd1")!, factoryCalibration: FactoryCalibration(i1: 1, i2: 2, i3: 4, i4: 8, i5: 16, i6: 32), family: .unknown, type: .virtual, region: .european, serial: "OBIR2PO", state: .ready, age: 120, lifetime: 24 * 60)
    var targetValue = 100
    var transmitter: Transmitter?
}
