//
//  GlucoseQuality.swift
//  LibreDirect
//

import Foundation

struct GlucoseQuality: OptionSet, Codable {
    static let OK = GlucoseQuality([])
    static let SD14_FIFO_OVERFLOW = GlucoseQuality(rawValue: 1 << 0)
    static let FILTER_DELTA = GlucoseQuality(rawValue: 1 << 1)
    static let WORK_VOLTAGE = GlucoseQuality(rawValue: 1 << 2)
    static let PEAK_DELTA_EXCEEDED = GlucoseQuality(rawValue: 1 << 3)
    static let AVG_DELTA_EXCEEDED = GlucoseQuality(rawValue: 1 << 4)
    static let RF = GlucoseQuality(rawValue: 1 << 5)
    static let REF_R = GlucoseQuality(rawValue: 1 << 6)
    static let SIGNAL_SATURATED = GlucoseQuality(rawValue: 1 << 7)
    static let SENSOR_SIGNAL_LOW = GlucoseQuality(rawValue: 1 << 8)
    static let THERMISTOR_OUT_OF_RANGE = GlucoseQuality(rawValue: 1 << 11)
    static let TEMP_HIGH = GlucoseQuality(rawValue: 1 << 13)
    static let TEMP_LOW = GlucoseQuality(rawValue: 1 << 14)
    static let INVALID_DATA = GlucoseQuality(rawValue: 1 << 15)

    let rawValue: Int

    var description: String {
        var outputs: [String] = []

        if self.contains(.SD14_FIFO_OVERFLOW) { outputs.append("SD14_FIFO_OVERFLOW") }
        if self.contains(.FILTER_DELTA) { outputs.append("FILTER_DELTA") }
        if self.contains(.WORK_VOLTAGE) { outputs.append("WORK_VOLTAGE") }
        if self.contains(.PEAK_DELTA_EXCEEDED) { outputs.append("PEAK_DELTA_EXCEEDED") }
        if self.contains(.AVG_DELTA_EXCEEDED) { outputs.append("AVG_DELTA_EXCEEDED") }
        if self.contains(.RF) { outputs.append("RF") }
        if self.contains(.REF_R) { outputs.append("REF_R") }
        if self.contains(.SIGNAL_SATURATED) { outputs.append("SIGNAL_SATURATED") }
        if self.contains(.SENSOR_SIGNAL_LOW) { outputs.append("SENSOR_SIGNAL_LOW") }
        if self.contains(.THERMISTOR_OUT_OF_RANGE) { outputs.append("THERMISTOR_OUT_OF_RANGE") }
        if self.contains(.TEMP_HIGH) { outputs.append("TEMP_HIGH") }
        if self.contains(.TEMP_LOW) { outputs.append("TEMP_LOW") }
        if self.contains(.INVALID_DATA) { outputs.append("INVALID_DATA") }

        return outputs.joined(separator: ", ")
    }
}
