//
//  SensorGlucoseActivityAttributes.swift
//  GlucoseDirect
//

import ActivityKit
import Foundation

// MARK: - SensorGlucoseActivityAttributes

struct SensorGlucoseActivityAttributes: ActivityAttributes {
    public typealias GlucoseStatus = ContentState

    public struct ContentState: Codable, Hashable {
        var alarmLow: Int
        var alarmHigh: Int

        var sensorState: SensorState?
        var connectionState: SensorConnectionState?

        var glucose: SensorGlucose?
        var glucoseUnit: GlucoseUnit?

        var startDate: Date?
        var restartDate: Date?
        var stopDate: Date?
    }
}
