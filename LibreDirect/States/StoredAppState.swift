//
//  UserDefaultsAppState.swift
//  LibreDirect
//

import Combine
import CoreNFC
import Foundation
import UserNotifications

// MARK: - DatabaseState

struct DatabaseState: AppState {
    var alarmHigh: Int = 160
    var alarmLow: Int = 80
    var alarmSnoozeUntil: Date?
    var bellmanAlarm = false
    var bellmanConnectionState: BellmanConnectionState = .disconnected
    var calendarExport: Bool = false
    var chartShowLines: Bool
    var chartZoomLevel: Int
    var connectionAlarmSound: NotificationSound
    var connectionError: String?
    var connectionErrorIsCritical = false
    var connectionErrorTimestamp: Date?
    var connectionInfos: [SensorConnectionInfo] = []
    var connectionState: SensorConnectionState = .disconnected
    var customCalibration: [CustomCalibration]
    var expiringAlarmSound: NotificationSound
    var glucoseBadge: Bool
    var glucoseUnit: GlucoseUnit
    var glucoseValues: [Glucose]
    var highGlucoseAlarmSound: NotificationSound
    var ignoreMute: Bool
    var internalHttpServer: Bool
    var isPaired: Bool
    var lowGlucoseAlarmSound: NotificationSound
    var missedReadings: Int = 0
    var nightscoutApiSecret: String
    var nightscoutUpload: Bool
    var nightscoutURL: String
    var readGlucose: Bool
    var selectedCalendarTarget: String?
    var selectedConnection: SensorBLEConnection?
    var selectedConnectionID: String?
    var selectedView: Int
    var sensor: Sensor?
    var sensorInterval: Int
    var targetValue: Int = 100
    var transmitter: Transmitter?
}

// MARK: - UserDefaultsState

struct UserDefaultsState: AppState {
    // MARK: Lifecycle

    init() {
        #if targetEnvironment(simulator)
            let defaultConnectionID = "virtual"
        #else
            let defaultConnectionID = NFCTagReaderSession.readingAvailable
                ? "libre2"
                : "bubble"
        #endif

        if let alarmHigh = UserDefaults.standard.alarmHigh {
            self.alarmHigh = alarmHigh
        }

        if let alarmLow = UserDefaults.standard.alarmLow {
            self.alarmLow = alarmLow
        }

        self.bellmanAlarm = UserDefaults.standard.bellmanAlarm
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
        self.nightscoutURL = UserDefaults.standard.nightscoutURL
        self.nightscoutUpload = UserDefaults.standard.nightscoutUpload
        self.readGlucose = UserDefaults.standard.readGlucose
        self.selectedCalendarTarget = UserDefaults.standard.selectedCalendarTarget
        self.selectedConnectionID = UserDefaults.standard.selectedConnectionID ?? defaultConnectionID
        self.selectedView = UserDefaults.standard.selectedView
        self.sensor = UserDefaults.standard.sensor
        self.sensorInterval = UserDefaults.standard.sensorInterval
        self.transmitter = UserDefaults.standard.transmitter
        self.connectionAlarmSound = UserDefaults.standard.connectionAlarmSound
        self.expiringAlarmSound = UserDefaults.standard.expiringAlarmSound
        self.highGlucoseAlarmSound = UserDefaults.standard.highGlucoseAlarmSound
        self.lowGlucoseAlarmSound = UserDefaults.standard.lowGlucoseAlarmSound
    }

    // MARK: Internal

    var alarmSnoozeUntil: Date?

    var bellmanConnectionState: BellmanConnectionState = .disconnected

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

    var bellmanAlarm = false {
        didSet {
            UserDefaults.standard.bellmanAlarm = bellmanAlarm
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

    var highGlucoseAlarmSound: NotificationSound {
        didSet {
            UserDefaults.standard.highGlucoseAlarmSound = highGlucoseAlarmSound
        }
    }

    var ignoreMute: Bool {
        didSet {
            UserDefaults.standard.ignoreMute = ignoreMute
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

    var lowGlucoseAlarmSound: NotificationSound {
        didSet {
            UserDefaults.standard.lowGlucoseAlarmSound = lowGlucoseAlarmSound
        }
    }

    var nightscoutApiSecret: String {
        didSet {
            UserDefaults.standard.nightscoutApiSecret = nightscoutApiSecret
        }
    }

    var nightscoutURL: String {
        didSet {
            UserDefaults.standard.nightscoutURL = nightscoutURL
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

    var selectedConnectionID: String? {
        didSet {
            UserDefaults.standard.selectedConnectionID = selectedConnectionID
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

    var sensorInterval: Int {
        didSet {
            UserDefaults.standard.sensorInterval = sensorInterval
        }
    }

    var transmitter: Transmitter? {
        didSet {
            UserDefaults.standard.transmitter = transmitter
        }
    }
}
