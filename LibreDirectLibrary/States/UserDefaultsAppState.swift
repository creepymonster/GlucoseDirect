//
//  UserDefaultsAppState.swift
//  LibreDirect
//

import Combine
import Foundation
import UserNotifications

struct UserDefaultsAppState: AppState {
    // MARK: Lifecycle

    init() {
        if let alarmHigh = UserDefaults.standard.alarmHigh {
            self.alarmHigh = alarmHigh
        }

        if let alarmLow = UserDefaults.standard.alarmLow {
            self.alarmLow = alarmLow
        }

        self.chartShowLines = UserDefaults.standard.chartShowLines
        self.glucoseValues = UserDefaults.standard.glucoseValues
        self.nightscoutUpload = UserDefaults.standard.nightscoutUpload
        self.nightscoutApiSecret = UserDefaults.standard.nightscoutApiSecret
        self.nightscoutHost = UserDefaults.standard.nightscoutHost
        self.glucoseUnit = UserDefaults.standard.glucoseUnit
        self.sensor = UserDefaults.standard.sensor
    }

    init(connectionState: SensorConnectionState, sensor: Sensor, currentGlucose: Glucose) {
        self.connectionState = connectionState
        self.sensor = sensor
        self.glucoseValues = [currentGlucose]
    }

    // MARK: Internal

    var alarmSnoozeUntil: Date?
    var connectionError: String?
    var connectionErrorTimestamp: Date?
    var connectionState: SensorConnectionState = .disconnected
    var missedReadings: Int = 0
    var targetValue: Int = 100
    var selectedView: Int = 1

    var chartShowLines: Bool = false {
        didSet {
            UserDefaults.standard.chartShowLines = chartShowLines
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

    var glucoseUnit: GlucoseUnit = .mgdL {
        didSet {
            UserDefaults.standard.glucoseUnit = glucoseUnit
        }
    }

    var glucoseValues: [Glucose] = [] {
        didSet {
            UserDefaults.standard.glucoseValues = glucoseValues
        }
    }

    var nightscoutApiSecret: String = "" {
        didSet {
            UserDefaults.standard.nightscoutApiSecret = nightscoutApiSecret
        }
    }

    var nightscoutHost: String = "" {
        didSet {
            UserDefaults.standard.nightscoutHost = nightscoutHost
        }
    }

    var nightscoutUpload: Bool = false {
        didSet {
            UserDefaults.standard.nightscoutUpload = nightscoutUpload
        }
    }

    var sensor: Sensor? {
        didSet {
            UserDefaults.standard.sensor = sensor
        }
    }
}
