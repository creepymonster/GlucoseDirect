//
//  PreviewAppReducer.swift
//  LibreDirect
//

import Combine
import Foundation

private var sensorBackup: Sensor? = nil

func previewAppReducer(state: inout AppState, action: AppAction) {
}

// MARK: - fileprivate

private var resetableStates: Set<SensorConnectionState> = [.connected, .powerOff, .scanning]
private var disconnectedStates: Set<SensorConnectionState> = [.disconnected, .scanning]
