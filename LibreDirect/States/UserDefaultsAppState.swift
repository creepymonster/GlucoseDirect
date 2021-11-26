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
        self.alarm = UserDefaults.standard.alarm
        
        if let alarmHigh = UserDefaults.standard.alarmHigh {
            self.alarmHigh = alarmHigh
        }

        if let alarmLow = UserDefaults.standard.alarmLow {
            self.alarmLow = alarmLow
        }
        
        self.chartShowLines = UserDefaults.standard.chartShowLines
        self.glucoseUnit = UserDefaults.standard.glucoseUnit
        self.glucoseValues = UserDefaults.standard.glucoseValues
        self.nightscoutApiSecret = UserDefaults.standard.nightscoutApiSecret
        self.nightscoutHost = UserDefaults.standard.nightscoutHost
        self.nightscoutUpload = UserDefaults.standard.nightscoutUpload
        self.selectedView = UserDefaults.standard.selectedView
        self.sensor = UserDefaults.standard.sensor
    }

    init(connectionState: SensorConnectionState, sensor: Sensor, currentGlucose: Glucose) {
        self.connectionState = connectionState
        self.sensor = sensor
        self.glucoseValues = [currentGlucose]
    }

    // MARK: Internal
    
    var alarm: Bool = false {
        didSet {
            UserDefaults.standard.alarm = alarm
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

    var alarmSnoozeUntil: Date?
    
    var chartShowLines: Bool = false {
        didSet {
            UserDefaults.standard.chartShowLines = chartShowLines
        }
    }
    
    var connectionError: String?
    
    var connectionErrorTimestamp: Date?
    
    var connectionState: SensorConnectionState = .disconnected
    
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
    
    var missedReadings: Int = 0
    
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

    var selectedView: Int = 1 {
        didSet {
            UserDefaults.standard.selectedView = selectedView
        }
    }
    
    var sensor: Sensor? {
        didSet {
            UserDefaults.standard.sensor = sensor
        }
    }
    
    var targetValue: Int = 100
}
