//
//  AppState.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 06.07.21.
//

import Foundation
import Combine

protocol AppState {
    var connectionError: String? { get set }
    var connectionErrorTimestamp: Date? { get set }
    
    var connectionState: SensorConnectionState { get set }
    var nightscoutApiSecret: String { get set }
    var nightscoutHost: String { get set }
    var sensor: Sensor? { get set }
    var glucoseValues: [SensorGlucose] { get set }
    
    var alarmSnoozeUntil: Date? { get set }
    var alarmLow: Int { get set }
    var alarmHigh: Int { get set }

    var lastGlucose: SensorGlucose? { get }
    var isPairable: Bool { get }
    var isPaired: Bool { get }
    var isConnectable: Bool { get }
    var isDisconnectable: Bool { get }
    var isReady: Bool { get }
}
