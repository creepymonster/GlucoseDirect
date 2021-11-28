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
        self.glucoseAlarm = UserDefaults.standard.glucoseAlarm
        self.expiringAlarm = UserDefaults.standard.expiringAlarm
        self.connectionAlarm = UserDefaults.standard.connectionAlarm
        
        if let alarmHigh = UserDefaults.standard.alarmHigh {
            self.alarmHigh = alarmHigh
        }

        if let alarmLow = UserDefaults.standard.alarmLow {
            self.alarmLow = alarmLow
        }
        
        self.chartShowLines = UserDefaults.standard.chartShowLines
        self.glucoseBadge = UserDefaults.standard.glucoseBadge
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
    
    var glucoseAlarm: Bool = true {
        didSet {
            UserDefaults.standard.glucoseAlarm = glucoseAlarm
        }
    }
    
    var expiringAlarm: Bool = true {
        didSet {
            UserDefaults.standard.expiringAlarm = expiringAlarm
        }
    }
    
    var connectionAlarm: Bool = true {
        didSet {
            UserDefaults.standard.connectionAlarm = connectionAlarm
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
    
    var glucoseBadge = true {
        didSet {
            UserDefaults.standard.glucoseBadge = glucoseBadge
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
