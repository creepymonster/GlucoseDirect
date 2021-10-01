//
//  DefaultAppState.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation
import Combine
import UserNotifications

public struct DefaultAppState: AppState {
    public var alarmHigh: Int = 180 {
        didSet {
            UserDefaults.appGroup.alarmHigh = alarmHigh
        }
    }

    public var alarmLow: Int = 70 {
        didSet {
            UserDefaults.appGroup.alarmLow = alarmLow
        }
    }

    public var alarmSnoozeUntil: Date?
    public var connectionError: String?
    public var connectionErrorTimeStamp: Date?
    public var connectionState: SensorConnectionState = .disconnected

    public var glucoseUnit: GlucoseUnit = .mgdL {
        didSet {
            UserDefaults.appGroup.glucoseUnit = glucoseUnit
        }
    }

    public var glucoseValues: [SensorGlucose] = [] {
        didSet {
            UserDefaults.appGroup.glucoseValues = glucoseValues
            UserDefaults.appGroup.lastGlucose = glucoseValues.last
        }
    }

    public var missedReadings: Int = 0

    public var nightscoutUpload: Bool = false {
        didSet {
            UserDefaults.appGroup.nightscoutUpload = nightscoutUpload
        }
    }

    public var nightscoutApiSecret: String = "" {
        didSet {
            UserDefaults.appGroup.nightscoutApiSecret = nightscoutApiSecret
        }
    }

    public var nightscoutHost: String = "" {
        didSet {
            UserDefaults.appGroup.nightscoutHost = nightscoutHost
        }
    }

    public var sensor: Sensor? = nil {
        didSet {
            UserDefaults.appGroup.sensor = sensor
        }
    }

    public init() {
        if let alarmHigh = UserDefaults.appGroup.alarmHigh {
            self.alarmHigh = alarmHigh
        }

        if let alarmLow = UserDefaults.appGroup.alarmLow {
            self.alarmLow = alarmLow
        }

        self.glucoseValues = UserDefaults.appGroup.glucoseValues
        self.nightscoutUpload = UserDefaults.appGroup.nightscoutUpload
        self.nightscoutApiSecret = UserDefaults.appGroup.nightscoutApiSecret
        self.nightscoutHost = UserDefaults.appGroup.nightscoutHost
        self.glucoseUnit = UserDefaults.appGroup.glucoseUnit
        self.sensor = UserDefaults.appGroup.sensor
    }

    public init(connectionState: SensorConnectionState, sensor: Sensor, lastGlucose: SensorGlucose) {
        self.connectionState = connectionState
        self.sensor = sensor
        self.glucoseValues = [lastGlucose]
    }
}
