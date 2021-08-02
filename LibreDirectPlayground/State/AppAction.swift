//
//  AppAction.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation

enum AppAction {
    case connectSensor
    case disconnectSensor
    case pairSensor
    case resetSensor

    case setSensor(value: Sensor)
    case setSensorConnection(connectionUpdate: SensorConnectionUpdate)
    case setSensorReading(readingUpdate: SensorReadingUpdate)
    case setSensorAge(ageUpdate: SensorAgeUpdate)
    case setSensorError(errorUpdate: SensorErrorUpdate)

    case setNightscoutHost(host: String)
    case setNightscoutSecret(apiSecret: String)
    
    case setAlarmLow(value: Int)
    case setAlarmHigh(value: Int)
    case setAlarmSnoozeUntil(value: Date?)
    
    case setGlucoseUnit(value: GlucoseUnit)

    case subscribeForUpdates
}
