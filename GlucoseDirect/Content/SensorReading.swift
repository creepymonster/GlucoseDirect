//
//  SensorReading.swift
//  GlucoseDirect
//

import Foundation

final class SensorReading: CustomStringConvertible, Codable {
    // MARK: Lifecycle

    init(id: UUID, timestamp: Date, quality: GlucoseQuality) {
        self.id = id
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.glucoseValue = nil
        self.quality = quality
    }

    init(id: UUID, timestamp: Date, glucoseValue: Double, quality: GlucoseQuality = .OK) {
        self.id = id
        self.timestamp = timestamp.toRounded(on: 1, .minute)

        if quality == .OK {
            self.glucoseValue = glucoseValue
        } else {
            self.glucoseValue = nil
        }

        self.quality = quality
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let glucoseValue: Double?
    let quality: GlucoseQuality

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.toLocalTime())",
            "glucoseValue: \(glucoseValue?.description ?? "-")",
            "quality: \(quality.description)"
        ].joined(separator: ", ")
    }
}
