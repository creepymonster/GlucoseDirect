//
//  UserDefaultsAppState.swift
//  LibreDirect
//

import Combine
import Foundation
import UserNotifications

#if canImport(CoreNFC)
    import CoreNFC
#endif

// MARK: - UserDefaultsState

struct UserDefaultsState: AppState {
    // MARK: Lifecycle

    init() {
        #if targetEnvironment(simulator)
            let defaultConnectionID = "virtual"
        #else
            #if canImport(CoreNFC)
                let defaultConnectionID = NFCTagReaderSession.readingAvailable
                    ? "libre2"
                    : "bubble"
            #else
                let defaultConnectionID = "bubble"
            #endif
        #endif

        if let alarmHigh = UserDefaults.standard.alarmHigh {
            self.alarmHigh = alarmHigh
        }

        if let alarmLow = UserDefaults.standard.alarmLow {
            self.alarmLow = alarmLow
        }

        self.bellmanAlarm = UserDefaults.standard.bellmanAlarm
        self.appleCalendarExport = UserDefaults.standard.appleCalendarExport
        self.appleHealthExport = UserDefaults.standard.appleHealthExport
        self.chartShowLines = UserDefaults.standard.chartShowLines
        self.chartZoomLevel = UserDefaults.standard.chartZoomLevel
        self.customCalibration = UserDefaults.standard.customCalibration
        self.connectionPeripheralUUID = UserDefaults.standard.connectionPeripheralUUID
        self.glucoseValues = UserDefaults.standard.glucoseValues
        self.glucoseNotification = UserDefaults.standard.glucoseNotification
        self.glucoseUnit = UserDefaults.standard.glucoseUnit
        self.isConnectionPaired = UserDefaults.standard.isConnectionPaired
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

    var appleCalendarExport: Bool = false {
        didSet {
            UserDefaults.standard.appleCalendarExport = appleCalendarExport
        }
    }

    var appleHealthExport = false {
        didSet {
            UserDefaults.standard.appleHealthExport = appleHealthExport
        }
    }

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
    
    var connectionPeripheralUUID: String? {
        didSet {
            UserDefaults.standard.connectionPeripheralUUID = connectionPeripheralUUID
        }
    }

    var expiringAlarmSound: NotificationSound {
        didSet {
            UserDefaults.standard.expiringAlarmSound = expiringAlarmSound
        }
    }

    var glucoseNotification: Bool {
        didSet {
            UserDefaults.standard.glucoseNotification = glucoseNotification
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

    var isConnectionPaired: Bool {
        didSet {
            UserDefaults.standard.isConnectionPaired = isConnectionPaired
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
