//
//  UserDefaultsAppState.swift
//  GlucoseDirect
//

import Combine
import Foundation
import UserNotifications

#if canImport(CoreNFC)
    import CoreNFC
#endif

// MARK: - AppState

struct AppState: DirectState {
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

        if UserDefaults.shared.glucoseUnit == nil {
            UserDefaults.shared.glucoseUnit = UserDefaults.standard.glucoseUnit ?? .mgdL
        }

        if let sensor = UserDefaults.standard.sensor, UserDefaults.shared.sensor == nil {
            UserDefaults.shared.sensor = sensor
        }

        if let transmitter = UserDefaults.standard.transmitter, UserDefaults.shared.transmitter == nil {
            UserDefaults.shared.transmitter = transmitter
        }

        if let alarmHigh = UserDefaults.standard.alarmHigh {
            self.alarmHigh = alarmHigh
        }

        if let alarmLow = UserDefaults.standard.alarmLow {
            self.alarmLow = alarmLow
        }

        self.appleCalendarExport = UserDefaults.standard.appleCalendarExport
        self.appleHealthExport = UserDefaults.standard.appleHealthExport
        self.bellmanAlarm = UserDefaults.standard.bellmanAlarm
        self.chartShowLines = UserDefaults.standard.chartShowLines
        self.chartZoomLevel = UserDefaults.standard.chartZoomLevel
        self.connectionAlarmSound = UserDefaults.standard.connectionAlarmSound
        self.connectionPeripheralUUID = UserDefaults.standard.connectionPeripheralUUID
        self.customCalibration = UserDefaults.standard.customCalibration
        self.expiringAlarmSound = UserDefaults.standard.expiringAlarmSound
        self.glucoseNotification = UserDefaults.standard.glucoseNotification
        self.glucoseUnit = UserDefaults.shared.glucoseUnit ?? .mgdL
        self.highGlucoseAlarmSound = UserDefaults.standard.highGlucoseAlarmSound
        self.isConnectionPaired = UserDefaults.standard.isConnectionPaired
        self.latestBloodGlucose = UserDefaults.shared.latestBloodGlucose
        self.latestSensorGlucose = UserDefaults.shared.latestSensorGlucose
        self.latestSensorError = UserDefaults.shared.latestSensorError
        self.lowGlucoseAlarmSound = UserDefaults.standard.lowGlucoseAlarmSound
        self.nightscoutApiSecret = UserDefaults.standard.nightscoutApiSecret
        self.nightscoutUpload = UserDefaults.standard.nightscoutUpload
        self.nightscoutURL = UserDefaults.standard.nightscoutURL
        self.readGlucose = UserDefaults.standard.readGlucose
        self.selectedCalendarTarget = UserDefaults.standard.selectedCalendarTarget
        self.selectedConnectionID = UserDefaults.standard.selectedConnectionID ?? defaultConnectionID
        self.selectedView = UserDefaults.standard.selectedView
        self.sensor = UserDefaults.shared.sensor
        self.sensorInterval = UserDefaults.standard.sensorInterval
        self.transmitter = UserDefaults.shared.transmitter
    }

    // MARK: Internal

    var alarmHigh: Int = 160 { didSet { UserDefaults.standard.alarmHigh = alarmHigh } }
    var alarmLow: Int = 80 { didSet { UserDefaults.standard.alarmLow = alarmLow } }
    var alarmSnoozeUntil: Date?
    var appleCalendarExport: Bool { didSet { UserDefaults.standard.appleCalendarExport = appleCalendarExport } }
    var appleHealthExport: Bool { didSet { UserDefaults.standard.appleHealthExport = appleHealthExport } }
    var bellmanAlarm = false { didSet { UserDefaults.standard.bellmanAlarm = bellmanAlarm } }
    var bellmanConnectionState: BellmanConnectionState = .disconnected
    var bloodGlucoseHistory: [BloodGlucose] = []
    var bloodGlucoseValues: [BloodGlucose] = []
    var chartShowLines: Bool { didSet { UserDefaults.standard.chartShowLines = chartShowLines } }
    var chartZoomLevel: Int { didSet { UserDefaults.standard.chartZoomLevel = chartZoomLevel } }
    var connectionAlarmSound: NotificationSound { didSet { UserDefaults.standard.connectionAlarmSound = connectionAlarmSound } }
    var connectionError: String?
    var connectionErrorIsCritical = false
    var connectionErrorTimestamp: Date?
    var connectionInfos: [SensorConnectionInfo] = []
    var connectionPeripheralUUID: String? { didSet { UserDefaults.standard.connectionPeripheralUUID = connectionPeripheralUUID } }
    var connectionState: SensorConnectionState = .disconnected
    var customCalibration: [CustomCalibration] { didSet { UserDefaults.standard.customCalibration = customCalibration } }
    var expiringAlarmSound: NotificationSound { didSet { UserDefaults.standard.expiringAlarmSound = expiringAlarmSound } }
    var glucoseNotification: Bool { didSet { UserDefaults.standard.glucoseNotification = glucoseNotification } }
    var glucoseUnit: GlucoseUnit { didSet { UserDefaults.shared.glucoseUnit = glucoseUnit } }
    var highGlucoseAlarmSound: NotificationSound { didSet { UserDefaults.standard.highGlucoseAlarmSound = highGlucoseAlarmSound } }
    var isConnectionPaired: Bool { didSet { UserDefaults.standard.isConnectionPaired = isConnectionPaired } }
    var latestBloodGlucose: BloodGlucose? { didSet { UserDefaults.shared.latestBloodGlucose = latestBloodGlucose } }
    var latestSensorError: SensorError? { didSet { UserDefaults.shared.latestSensorError = latestSensorError } }
    var latestSensorGlucose: SensorGlucose? { didSet { UserDefaults.shared.latestSensorGlucose = latestSensorGlucose } }
    var lowGlucoseAlarmSound: NotificationSound { didSet { UserDefaults.standard.lowGlucoseAlarmSound = lowGlucoseAlarmSound } }
    var nightscoutApiSecret: String { didSet { UserDefaults.standard.nightscoutApiSecret = nightscoutApiSecret } }
    var nightscoutUpload: Bool { didSet { UserDefaults.standard.nightscoutUpload = nightscoutUpload } }
    var nightscoutURL: String { didSet { UserDefaults.standard.nightscoutURL = nightscoutURL } }
    var preventScreenLock = false
    var readGlucose: Bool { didSet { UserDefaults.standard.readGlucose = readGlucose } }
    var selectedCalendarTarget: String? { didSet { UserDefaults.standard.selectedCalendarTarget = selectedCalendarTarget } }
    var selectedConnection: SensorConnectionProtocol?
    var selectedConnectionID: String? { didSet { UserDefaults.standard.selectedConnectionID = selectedConnectionID } }
    var selectedView: Int { didSet { UserDefaults.standard.selectedView = selectedView } }
    var sensor: Sensor? { didSet { UserDefaults.shared.sensor = sensor } }
    var sensorErrorValues: [SensorError] = []
    var sensorGlucoseHistory: [SensorGlucose] = []
    var sensorGlucoseValues: [SensorGlucose] = []
    var sensorInterval: Int { didSet { UserDefaults.standard.sensorInterval = sensorInterval } }
    var targetValue = 100
    var transmitter: Transmitter? { didSet { UserDefaults.shared.transmitter = transmitter } }
}
