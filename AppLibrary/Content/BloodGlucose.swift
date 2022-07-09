//
//  BloodGlucose.swift
//  GlucoseDirect
//

import Foundation

// MARK: - BloodGlucose

struct BloodGlucose: Glucose, CustomStringConvertible, Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let glucoseValue: Int

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.toLocalTime())",
            "glucoseValue: \(glucoseValue.description)",
        ].joined(separator: ", ")
    }
}
