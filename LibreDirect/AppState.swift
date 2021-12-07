//
//  AppState.swift
//  LibreDirect
//

import Combine
import Foundation

private var sensorConnectableStates: Set<SensorState> = [.starting, .ready]
private var connectableStates: Set<SensorConnectionState> = [.disconnected]
private var disconnectableStates: Set<SensorConnectionState> = [.connected, .connecting, .scanning]

// MARK: - AppState

protocol AppState {
    var alarmHigh: Int { get set }
    var alarmLow: Int { get set }
    var alarmSnoozeUntil: Date? { get set }
    var calendarExport: Bool { get set }
    var chartShowLines: Bool { get set }
    var connectionAlarm: Bool { get set }
    var connectionError: String? { get set }
    var connectionErrorTimestamp: Date? { get set }
    var connectionInfos: [SensorConnectionInfo] { get set }
    var connectionState: SensorConnectionState { get set }
    var expiringAlarm: Bool { get set }
    var glucoseAlarm: Bool { get set }
    var glucoseBadge: Bool { get set }
    var glucoseUnit: GlucoseUnit { get set }
    var glucoseValues: [Glucose] { get set }
    var missedReadings: Int { get set }
    var nightscoutApiSecret: String { get set }
    var nightscoutHost: String { get set }
    var nightscoutUpload: Bool { get set }
    var selectedCalendarTarget: String? { get set }
    var selectedConnection: SensorConnection? { get set }
    var selectedConnectionId: String? { get set }
    var selectedView: Int { get set }
    var sensor: Sensor? { get set }
    var targetValue: Int { get set }
    var transmitter: Transmitter? { get set }
}

extension AppState {
    var currentGlucose: Glucose? { glucoseValues.last }

    var isConnectable: Bool {
        if transmitter != nil, connectableStates.contains(connectionState) {
            return true
        }

        if let sensor = sensor {
            return sensorConnectableStates.contains(sensor.state) && connectableStates.contains(connectionState)
        }

        return false
    }

    var hasSelectedConnection: Bool { selectedConnection != nil }

    var isDisconnectable: Bool { disconnectableStates.contains(connectionState) }

    var isPaired: Bool { isSensorPaired || isTransmitterPaired }

    var isSensorPaired: Bool { sensor != nil }

    var isTransmitterPaired: Bool { transmitter != nil }

    var isReady: Bool { sensor != nil && sensor!.state == .ready }

    var lastGlucose: Glucose? { glucoseValues.suffix(2).first }

    var limitedGlucoseValues: [Glucose] {
        glucoseValues.filter { glucose in
            glucose.is5Minutely
        }
    }
}
