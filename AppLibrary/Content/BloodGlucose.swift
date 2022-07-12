//
//  BloodGlucose.swift
//  GlucoseDirect
//

import Foundation

// MARK: - BloodGlucose

struct BloodGlucose: Glucose, CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle

    init(timestamp: Date, glucoseValue: Int) {
        let roundedTimestamp = timestamp.toRounded(on: 1, .minute)

        self.id = UUID()
        self.timestamp = roundedTimestamp
        self.glucoseValue = glucoseValue
        self.timegroup = roundedTimestamp.toRounded(on: 15, .minute)
    }

    init(id: UUID, timestamp: Date, glucoseValue: Int) {
        let roundedTimestamp = timestamp.toRounded(on: 1, .minute)

        self.id = id
        self.timestamp = roundedTimestamp
        self.glucoseValue = glucoseValue
        self.timegroup = roundedTimestamp.toRounded(on: 15, .minute)
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let glucoseValue: Int
    let timegroup: Date

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.toLocalTime())",
            "glucoseValue: \(glucoseValue.description)",
        ].joined(separator: ", ")
    }
}
