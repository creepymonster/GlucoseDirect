//
//  AppReducers.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

func defaultAppReducer(state: inout AppState, action: AppAction) -> Void {
    switch action {
    case .connectSensor:
        break

    case .disconnectSensor:
        break

    case .pairSensor:
        break

    case .resetSensor:
        state.sensor = nil
        state.connectionError = nil

    case .setSensor(value: let value):
        state.sensor = value

    case .setSensorConnection(connectionUpdate: let connectionUpdate):
        state.connectionState = connectionUpdate.connectionState

        if resetableStates.contains(connectionUpdate.connectionState) {
            state.connectionError = nil
        }

    case .setSensorReading(readingUpdate: let readingUpdate):
        if let lastGlucoseTrend = readingUpdate.glucoseTrend.sorted(by: { $0.timeStamp > $1.timeStamp }).first {
            state.glucoseTrend = [lastGlucoseTrend]
        }

    case .setSensorAge(ageUpdate: let ageUpdate):
        guard state.sensor != nil else {
            return
        }

        state.sensor!.age = ageUpdate.sensorAge

    case .setSensorError(errorUpdate: let errorUpdate):
        state.connectionError = errorUpdate.errorMessage

    case .setNightscoutHost(host: let host):
        state.nightscoutHost = host

    case .setNightscoutSecret(apiSecret: let apiSecret):
        state.nightscoutApiSecret = apiSecret

    case .subscribeForUpdates:
        break

    }
}

fileprivate var resetableStates: Set<SensorConnectionState> = [.connected, .powerOff, .scanning]
