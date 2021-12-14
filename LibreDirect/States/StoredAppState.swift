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
        self.glucoseAlarm = UserDefaults.standard.glucoseAlarm
        self.glucoseBadge = UserDefaults.standard.glucoseBadge
        self.glucoseUnit = UserDefaults.standard.glucoseUnit
        self.nightscoutApiSecret = UserDefaults.standard.nightscoutApiSecret
        self.nightscoutHost = UserDefaults.standard.nightscoutHost
        self.nightscoutUpload = UserDefaults.standard.nightscoutUpload
        self.selectedCalendarTarget = UserDefaults.standard.selectedCalendarTarget
        self.selectedConnectionId = UserDefaults.standard.selectedConnectionId ?? "libre2"
        self.selectedView = UserDefaults.standard.selectedView
        self.sensor = UserDefaults.standard.sensor
        self.transmitter = UserDefaults.standard.transmitter

        if !UserDefaults.standard.glucoseValues.isEmpty {
            var glucoseIds = [String?](repeating: nil, count: AppConfig.NumberOfGlucoseValues)
            var glucoseValues = [Glucose?](repeating: nil, count: AppConfig.NumberOfGlucoseValues)
            var index = 0

            let oldGlucoseValues = UserDefaults.standard.glucoseValues[..<AppConfig.NumberOfGlucoseValues]
            oldGlucoseValues.forEach {
                UserDefaults.standard.addGlucoseValue(glucose: $0)

                glucoseIds[index] = $0.id.uuidString
                glucoseValues[index] = $0
                index += 1
            }

            self.glucoseValues = glucoseValues.compactMap { $0 }

            UserDefaults.standard.glucoseValues = []
        } else {
            var glucoseValues = [Glucose?](repeating: nil, count: AppConfig.NumberOfGlucoseValues)
            var index = 0

            let ids = UserDefaults.standard.glucoseIds[0 ..< AppConfig.NumberOfGlucoseValues]
            ids.forEach {
                if let glucose = UserDefaults.standard.getGlucoseValue(id: $0) {
                    glucoseValues[index] = glucose
                    index += 1
                }
            }

            self.glucoseValues = glucoseValues.compactMap { $0 }
        }
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
            let differences = glucoseValues.difference(from: oldValue)
            for change in differences {
                switch change {
                case let .remove(_, oldElement, _):
                    UserDefaults.standard.removeGlucoseValue(id: oldElement.id)
                case let .insert(_, newElement, _):
                    UserDefaults.standard.addGlucoseValue(glucose: newElement)
                }
            }

            UserDefaults.standard.glucoseIds = glucoseValues.map { $0.id.uuidString }
        }
    }

    var nightscoutApiSecret: String {
        didSet {
            UserDefaults.standard.nightscoutApiSecret = nightscoutApiSecret
        }
    }

    var nightscoutHost: String {
        didSet {
            UserDefaults.standard.nightscoutHost = nightscoutHost
        }
    }

    var nightscoutUpload: Bool {
        didSet {
            UserDefaults.standard.nightscoutUpload = nightscoutUpload
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
