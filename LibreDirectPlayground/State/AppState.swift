//
//  AppState.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

protocol AppState {
    var alarmHigh: Int { get set }
    var alarmLow: Int { get set }
    var alarmSnoozeUntil: Date? { get set }
    var connectionError: String? { get set }
    var connectionErrorTimeStamp: Date? { get set }
    var connectionState: SensorConnectionState { get set }
    var glucoseUnit: GlucoseUnit { get set }
    var glucoseValues: [SensorGlucose] { get set }
    var nightscoutApiSecret: String { get set }
    var nightscoutHost: String { get set }
    var sensor: Sensor? { get set }
    
    var lastGlucose: SensorGlucose? { get }
    var isPairable: Bool { get }
    var isPaired: Bool { get }
    var isConnectable: Bool { get }
    var isDisconnectable: Bool { get }
    var isReady: Bool { get }
}
