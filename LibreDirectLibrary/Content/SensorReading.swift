//
//  SensorReading.swift
//  LibreDirect
//

import Foundation

final class SensorReading: CustomStringConvertible, Codable {
    // MARK: Lifecycle

    init(id: UUID, timestamp: Date, glucoseValue: Double) {
        self.id = id
        self.timestamp = timestamp.rounded(on: 1, .minute)
        self.glucoseValue = glucoseValue
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let glucoseValue: Double

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.localTime)",
            "glucoseValue: \(glucoseValue.description)"
        ].joined(separator: ", ")
    }
}
