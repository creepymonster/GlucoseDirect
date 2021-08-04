//
//  DefaultAppState.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine
import UserNotifications

class DefaultAppState: NSObject, AppState {
    var alarmHigh: Int = 180 {
        didSet {
            UserDefaults.appGroup.alarmHigh = alarmHigh
        }
    }

    var alarmLow: Int = 70 {
        didSet {
            UserDefaults.appGroup.alarmLow = alarmLow
        }
    }
    
    var alarmSnoozeUntil: Date?
    var connectionError: String?
    var connectionErrorTimeStamp: Date?
    var connectionState: SensorConnectionState = .disconnected
    
    var glucoseUnit: GlucoseUnit = .mgdL {
        didSet {
            UserDefaults.appGroup.glucoseUnit = glucoseUnit
        }
    }

    var glucoseValues: [SensorGlucose] = [] {
        didSet {
            UserDefaults.appGroup.glucoseValues = glucoseValues
            UserDefaults.appGroup.lastGlucose = glucoseValues.last
        }
    }

    var nightscoutApiSecret: String = "" {
        didSet {
            UserDefaults.appGroup.nightscoutApiSecret = nightscoutApiSecret
        }
    }

    var nightscoutHost: String = "" {
        didSet {
            UserDefaults.appGroup.nightscoutHost = nightscoutHost
        }
    }

    var sensor: Sensor? = nil {
        didSet {
            UserDefaults.appGroup.sensor = sensor
        }
    }

    override init() {
        super.init()
        
        if let alarmHigh = UserDefaults.appGroup.alarmHigh {
            self.alarmHigh = alarmHigh
        }
        
        if let alarmLow = UserDefaults.appGroup.alarmLow {
            self.alarmLow = alarmLow
        }
        
        self.glucoseValues = UserDefaults.appGroup.glucoseValues
        self.nightscoutApiSecret = UserDefaults.appGroup.nightscoutApiSecret
        self.nightscoutHost = UserDefaults.appGroup.nightscoutHost
        self.glucoseUnit = UserDefaults.appGroup.glucoseUnit
        self.sensor = UserDefaults.appGroup.sensor
        
        UNUserNotificationCenter.current().delegate = self
    }

    init(connectionState: SensorConnectionState, sensor: Sensor, lastGlucose: SensorGlucose) {
        self.connectionState = connectionState
        self.sensor = sensor
        self.glucoseValues = [lastGlucose]
    }
}

extension DefaultAppState: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .banner, .list, .sound])
    }
}

extension DefaultAppState {
    private static var connectableStates: Set<SensorConnectionState> = [.disconnected]
    private static var disconnectableStates: Set<SensorConnectionState> = [.connected, .connecting, .scanning]
    
    var lastGlucose: SensorGlucose? {
        get {
            return self.glucoseValues.last
        }
    }

    var isPairable: Bool {
        get {
            return sensor == nil
        }
    }

    var isPaired: Bool {
        get {
            return sensor != nil
        }
    }

    var isConnectable: Bool {
        get {
            return DefaultAppState.connectableStates.contains(connectionState)
        }
    }

    var isDisconnectable: Bool {
        get {
            return DefaultAppState.disconnectableStates.contains(connectionState)
        }
    }

    var isReady: Bool {
        get {
            return sensor != nil && sensor!.state == .ready
        }
    }
}
