//
//  UserDefaultsAppState.swift
//  LibreDirect
//

import Combine
import Foundation
import UserNotifications

struct StoredAppState: AppState {
    // MARK: Lifecycle

    init() {
        if let alarmHigh = UserDefaults.standard.alarmHigh {
            self.alarmHigh = alarmHigh
        }

        if let alarmLow = UserDefaults.standard.alarmLow {
            self.alarmLow = alarmLow
        }

        self.calendarExport = UserDefaults.standard.calendarExport
        self.chartShowLines = UserDefaults.standard.chartShowLines
        self.connectionAlarm = UserDefaults.standard.connectionAlarm
        self.expiringAlarm = UserDefaults.standard.expiringAlarm
        self.glucoseValues = UserDefaults.standard.glucoseValues
        self.glucoseAlarm = UserDefaults.standard.glucoseAlarm
        self.glucoseBadge = UserDefaults.standard.glucoseBadge
        self.glucoseUnit = UserDefaults.standard.glucoseUnit
        self.nightscoutApiSecret = UserDefaults.standard.nightscoutApiSecret
        self.nightscoutUrl = UserDefaults.standard.nightscoutUrl
        self.nightscoutUpload = UserDefaults.standard.nightscoutUpload
        self.readGlucose = UserDefaults.standard.readGlucose
        self.selectedCalendarTarget = UserDefaults.standard.selectedCalendarTarget
        self.selectedConnectionId = UserDefaults.standard.selectedConnectionId ?? "libre2"
        self.selectedView = UserDefaults.standard.selectedView
        self.sensor = UserDefaults.standard.sensor
        self.transmitter = UserDefaults.standard.transmitter
    }

    // MARK: Internal

    var alarmSnoozeUntil: Date?
    var connectionError: String?
    var connectionErrorIsCritical = false
    var connectionErrorTimestamp: Date?
    var connectionInfos: [SensorConnectionInfo] = []
    var connectionState: SensorConnectionState = .disconnected
    var missedReadings: Int = 0
    var selectedConnection: SensorConnection?
    var targetValue: Int = 100

    var alarmHigh: Int = 160 {
        didSet {
            UserDefaults.standard.alarmHigh = alarmHigh
        }
    }

    var alarmLow: Int = 80 {
        didSet {
            UserDefaults.standard.alarmLow = alarmLow
        }
    }

    var calendarExport: Bool = false {
        didSet {
            UserDefaults.standard.calendarExport = calendarExport
        }
    }

    var chartShowLines: Bool {
        didSet {
            UserDefaults.standard.chartShowLines = chartShowLines
        }
    }

    var connectionAlarm: Bool {
        didSet {
            UserDefaults.standard.connectionAlarm = connectionAlarm
        }
    }

    var expiringAlarm: Bool {
        didSet {
            UserDefaults.standard.expiringAlarm = expiringAlarm
        }
    }

    var glucoseAlarm: Bool {
        didSet {
            UserDefaults.standard.glucoseAlarm = glucoseAlarm
        }
    }

    var glucoseBadge: Bool {
        didSet {
            UserDefaults.standard.glucoseBadge = glucoseBadge
        }
    }

    var glucoseUnit: GlucoseUnit {
        didSet {
            UserDefaults.standard.glucoseUnit = glucoseUnit
        }
    }

    var glucoseValues: [Glucose] {
        didSet {
            UserDefaults.standard.glucoseValues = glucoseValues
        }
    }

    var nightscoutApiSecret: String {
        didSet {
            UserDefaults.standard.nightscoutApiSecret = nightscoutApiSecret
        }
    }

    var nightscoutUrl: String {
        didSet {
            UserDefaults.standard.nightscoutUrl = nightscoutUrl
        }
    }

    var nightscoutUpload: Bool {
        didSet {
            UserDefaults.standard.nightscoutUpload = nightscoutUpload
        }
    }

    var readGlucose: Bool {
        didSet {
            UserDefaults.standard.readGlucose = readGlucose
        }
    }

    var selectedCalendarTarget: String? {
        didSet {
            UserDefaults.standard.selectedCalendarTarget = selectedCalendarTarget
        }
    }

    var selectedConnectionId: String? {
        didSet {
            UserDefaults.standard.selectedConnectionId = selectedConnectionId
        }
    }

    var selectedView: Int {
        didSet {
            UserDefaults.standard.selectedView = selectedView
        }
    }

    var sensor: Sensor? {
        didSet {
            UserDefaults.standard.sensor = sensor
        }
    }

    var transmitter: Transmitter? {
        didSet {
            UserDefaults.standard.transmitter = transmitter
        }
    }
}
