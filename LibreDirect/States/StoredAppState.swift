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
        self.chartZoomLevel = UserDefaults.standard.chartZoomLevel
        self.customCalibration = UserDefaults.standard.customCalibration
        self.glucoseValues = UserDefaults.standard.glucoseValues
        self.glucoseBadge = UserDefaults.standard.glucoseBadge
        self.glucoseUnit = UserDefaults.standard.glucoseUnit
        self.internalHttpServer = UserDefaults.standard.internalHttpServer
        self.isPaired = UserDefaults.standard.isPaired
        self.ignoreMute = UserDefaults.standard.ignoreMute
        self.nightscoutApiSecret = UserDefaults.standard.nightscoutApiSecret
        self.nightscoutUrl = UserDefaults.standard.nightscoutUrl
        self.nightscoutUpload = UserDefaults.standard.nightscoutUpload
        self.readGlucose = UserDefaults.standard.readGlucose
        self.selectedCalendarTarget = UserDefaults.standard.selectedCalendarTarget
        self.selectedConnectionId = UserDefaults.standard.selectedConnectionId ?? "libre2"
        self.selectedView = UserDefaults.standard.selectedView
        self.sensor = UserDefaults.standard.sensor
        self.transmitter = UserDefaults.standard.transmitter
        self.connectionAlarmSound = UserDefaults.standard.connectionAlarmSound
        self.expiringAlarmSound = UserDefaults.standard.expiringAlarmSound
        self.highGlucoseAlarmSound = UserDefaults.standard.highGlucoseAlarmSound
        self.lowGlucoseAlarmSound = UserDefaults.standard.lowGlucoseAlarmSound
    }

    // MARK: Internal

    var alarmSnoozeUntil: Date?
    var connectionError: String?
    var connectionErrorIsCritical = false
    var connectionErrorTimestamp: Date?
    var connectionInfos: [SensorConnectionInfo] = []
    var connectionState: SensorConnectionState = .disconnected
    var missedReadings: Int = 0
    var selectedConnection: SensorBLEConnection?
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

    var chartZoomLevel: Int {
        didSet {
            UserDefaults.standard.chartZoomLevel = chartZoomLevel
        }
    }

    var connectionAlarmSound: NotificationSound {
        didSet {
            UserDefaults.standard.connectionAlarmSound = connectionAlarmSound
        }
    }
    
    var customCalibration: [CustomCalibration] {
        didSet {
            UserDefaults.standard.customCalibration = customCalibration
        }
    }

    var expiringAlarmSound: NotificationSound {
        didSet {
            UserDefaults.standard.expiringAlarmSound = expiringAlarmSound
        }
    }

    var highGlucoseAlarmSound: NotificationSound {
        didSet {
            UserDefaults.standard.highGlucoseAlarmSound = highGlucoseAlarmSound
        }
    }
    
    var lowGlucoseAlarmSound: NotificationSound {
        didSet {
            UserDefaults.standard.lowGlucoseAlarmSound = lowGlucoseAlarmSound
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

    var internalHttpServer: Bool {
        didSet {
            UserDefaults.standard.internalHttpServer = internalHttpServer
        }
    }
    
    var isPaired: Bool {
        didSet {
            UserDefaults.standard.isPaired = isPaired
        }
    }
    
    var ignoreMute: Bool {
        didSet {
            UserDefaults.standard.ignoreMute = ignoreMute
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
