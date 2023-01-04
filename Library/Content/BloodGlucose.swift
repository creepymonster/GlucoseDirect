//
//  BloodGlucose.swift
//  GlucoseDirect
//

import Foundation

// MARK: - BloodGlucose

struct BloodGlucose: Glucose, CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle

    init(timestamp: Date, glucoseValue: Int, originatingSource: String) {
        let roundedTimestamp = timestamp.toRounded(on: 1, .minute)

        self.id = UUID()
        self.timestamp = roundedTimestamp
        self.glucoseValue = glucoseValue
        self.timegroup = roundedTimestamp.toRounded(on: DirectConfig.timegroupRounding, .minute)
        self.originatingSource = originatingSource
    }

    init(id: UUID, timestamp: Date, glucoseValue: Int, originatingSource: String) {
        let roundedTimestamp = timestamp.toRounded(on: 1, .minute)

        self.id = id
        self.timestamp = roundedTimestamp
        self.glucoseValue = glucoseValue
        self.timegroup = roundedTimestamp.toRounded(on: DirectConfig.timegroupRounding, .minute)
        self.originatingSource = originatingSource
    }

    // MARK: Internal

    internal let id: UUID
    let timestamp: Date
    let glucoseValue: Int
    let timegroup: Date
    let originatingSource: String

    var description: String {
        "{ id: \(id), timestamp: \(timestamp.toLocalTime()), glucoseValue: \(glucoseValue.description), originatingSource: \(originatingSource) }"
    }
}
