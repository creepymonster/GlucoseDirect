//
//  AppAction.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation

public enum AppAction {
    case connectSensor
    case disconnectSensor
    case pairSensor
    case resetSensor

    case setAlarmHigh(value: Int)
    case setAlarmLow(value: Int)
    case setAlarmSnoozeUntil(value: Date?)

    case setGlucoseUnit(value: GlucoseUnit)
    case setNightscoutUpload(enabled: Bool)
    case setNightscoutHost(host: String)
    case setNightscoutSecret(apiSecret: String)

    case setSensor(value: Sensor)
    case setSensorAge(sensorAge: Int)
    case setSensorConnection(connectionState: SensorConnectionState)
    case setSensorError(errorMessage: String, errorTimestamp: Date)
    case setSensorReading(glucose: SensorGlucose)
    case setSensorMissedReadings
}

