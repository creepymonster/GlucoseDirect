//
//  DirectState.swift
//  GlucoseDirect
//

import Combine
import Foundation
import SwiftUI

// MARK: - DirectState

protocol DirectState {
    var appIsBusy: Bool { get set }
    var appSerial: String { get }
    var appState: ScenePhase { get set }
    var alarmHigh: Int { get set }
    var alarmLow: Int { get set }
    var alarmSnoozeUntil: Date? { get set }
    var appleCalendarExport: Bool { get set }
    var appleHealthExport: Bool { get set }
    var bellmanAlarm: Bool { get set }
    var bellmanConnectionState: BellmanConnectionState { get set }
    var bloodGlucoseValues: [BloodGlucose] { get set }
    var chartShowLines: Bool { get set }
    var chartZoomLevel: Int { get set }
    var connectionAlarmSound: NotificationSound { get set }
    var connectionError: String? { get set }
    var connectionErrorTimestamp: Date? { get set }
    var connectionInfos: [SensorConnectionInfo] { get set }
    var connectionPeripheralUUID: String? { get set }
    var connectionState: SensorConnectionState { get set }
    var customCalibration: [CustomCalibration] { get set }
    var expiringAlarmSound: NotificationSound { get set }
    var normalGlucoseNotification: Bool { get set }
    var alarmGlucoseNotification: Bool { get set }
    var glucoseLiveActivity: Bool { get set }
    var glucoseUnit: GlucoseUnit { get set }
    var highGlucoseAlarmSound: NotificationSound { get set }
    var ignoreMute: Bool { get set }
    var isConnectionPaired: Bool { get set }
    var latestBloodGlucose: BloodGlucose? { get set }
    var latestSensorGlucose: SensorGlucose? { get set }
    var latestSensorError: SensorError? { get set }
    var lowGlucoseAlarmSound: NotificationSound { get set }
    var nightscoutApiSecret: String { get set }
    var nightscoutUpload: Bool { get set }
    var nightscoutURL: String { get set }
    var preventScreenLock: Bool { get set }
    var readGlucose: Bool { get set }
    var selectedCalendarTarget: String? { get set }
    var selectedConnection: SensorConnectionProtocol? { get set }
    var selectedConnectionID: String? { get set }
    var selectedConfiguration: [SensorConnectionConfigurationOption] { get set }
    var selectedView: Int { get set }
    var minSelectedDate: Date { get set }
    var selectedDate: Date? { get set }
    var sensor: Sensor? { get set }
    var sensorErrorValues: [SensorError] { get set }
    var sensorGlucoseValues: [SensorGlucose] { get set }
    var sensorInterval: Int { get set }
    var showAnnotations: Bool { get set }
    var statisticsDays: Int { get set }
    var glucoseStatistics: GlucoseStatistics? { get set }
    var targetValue: Int { get set }
    var transmitter: Transmitter? { get set }
}

extension DirectState {
    var hasConnectionAlarm: Bool {
        connectionAlarmSound != .none
    }

    var hasExpiringAlarm: Bool {
        expiringAlarmSound != .none
    }

    var hasHighGlucoseAlarm: Bool {
        highGlucoseAlarmSound != .none
    }

    var hasLowGlucoseAlarm: Bool {
        lowGlucoseAlarmSound != .none
    }

    var isConnectable: Bool {
        if transmitter != nil, connectableStates.contains(connectionState) {
            return true
        }

        if let sensor = sensor {
            return sensorConnectableStates.contains(sensor.state) && connectableStates.contains(connectionState)
        }

        return false
    }

    var hasSelectedConnection: Bool {
        selectedConnection != nil
    }

    var isDisconnectable: Bool {
        disconnectableStates.contains(connectionState)
    }

    var isSensor: Bool {
        selectedConnection is IsSensor
    }

    var isTransmitter: Bool {
        selectedConnection is IsTransmitter
    }

    var isPairable: Bool {
        !isConnectionPaired && !(connectionState != .disconnected && connectionState != .pairing && connectionState != .scanning && connectionState != .connecting)
    }

    var connectionIsBusy: Bool {
        !(connectionState != .pairing && connectionState != .scanning && connectionState != .connecting)
    }

    var isReady: Bool {
        sensor != nil && sensor!.state == .ready
    }
}

// MARK: - private

private var sensorConnectableStates: Set<SensorState> = [.starting, .ready]
private var connectableStates: Set<SensorConnectionState> = [.disconnected]
private var disconnectableStates: Set<SensorConnectionState> = [.connected, .connecting, .scanning]
