//
//  AppState.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation
import Combine

fileprivate var connectableStates: Set<SensorConnectionState> = [.disconnected]
fileprivate var disconnectableStates: Set<SensorConnectionState> = [.connected, .connecting, .scanning]

public protocol AppState {
    var alarmHigh: Int { get set }
    var alarmLow: Int { get set }
    var alarmSnoozeUntil: Date? { get set }
    var connectionError: String? { get set }
    var connectionErrorTimeStamp: Date? { get set }
    var connectionState: SensorConnectionState { get set }
    var glucoseUnit: GlucoseUnit { get set }
    var glucoseValues: [SensorGlucose] { get set }
    var missedReadings: Int { get set }
    var nightscoutUpload: Bool { get set }
    var nightscoutApiSecret: String { get set }
    var nightscoutHost: String { get set }
    var sensor: Sensor? { get set }
}

public extension AppState {
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
            return connectableStates.contains(connectionState)
        }
    }

    var isDisconnectable: Bool {
        get {
            return disconnectableStates.contains(connectionState)
        }
    }

    var isReady: Bool {
        get {
            return sensor != nil && sensor!.state == .ready
        }
    }
}

