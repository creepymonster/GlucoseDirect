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
            UserDefaults.standard.alarmHigh = alarmHigh
        }
    }

    public var alarmLow: Int = 70 {
        didSet {
            UserDefaults.standard.alarmLow = alarmLow
        }
    }

    public var alarmSnoozeUntil: Date?
    public var connectionError: String?
    public var connectionErrorTimeStamp: Date?
    public var connectionState: SensorConnectionState = .disconnected

    public var glucoseUnit: GlucoseUnit = .mgdL {
        didSet {
            UserDefaults.standard.glucoseUnit = glucoseUnit
        }
    }

    public var glucoseValues: [SensorGlucose] = [] {
        didSet {
            UserDefaults.standard.glucoseValues = glucoseValues
            UserDefaults.standard.lastGlucose = glucoseValues.last
        }
    }

    public var missedReadings: Int = 0

    public var nightscoutUpload: Bool = false {
        didSet {
            UserDefaults.standard.nightscoutUpload = nightscoutUpload
        }
    }

    public var nightscoutApiSecret: String = "" {
        didSet {
            UserDefaults.standard.nightscoutApiSecret = nightscoutApiSecret
        }
    }

    public var nightscoutHost: String = "" {
        didSet {
            UserDefaults.standard.nightscoutHost = nightscoutHost
        }
    }

    public var sensor: Sensor? = nil {
        didSet {
            UserDefaults.standard.sensor = sensor
        }
    }
    
    public var deviceInfo: DeviceInfo? = nil {
        didSet {
            UserDefaults.standard.deviceInfo = deviceInfo
        }
    }

    public init() {
        if let alarmHigh = UserDefaults.standard.alarmHigh {
            self.alarmHigh = alarmHigh
        }

        if let alarmLow = UserDefaults.standard.alarmLow {
            self.alarmLow = alarmLow
        }

        self.glucoseValues = UserDefaults.standard.glucoseValues
        self.nightscoutUpload = UserDefaults.standard.nightscoutUpload
        self.nightscoutApiSecret = UserDefaults.standard.nightscoutApiSecret
        self.nightscoutHost = UserDefaults.standard.nightscoutHost
        self.glucoseUnit = UserDefaults.standard.glucoseUnit
        self.sensor = UserDefaults.standard.sensor
    }

    public init(connectionState: SensorConnectionState, sensor: Sensor, lastGlucose: SensorGlucose) {
        self.connectionState = connectionState
        self.sensor = sensor
        self.glucoseValues = [lastGlucose]
    }
}
