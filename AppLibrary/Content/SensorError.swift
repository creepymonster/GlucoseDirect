//
//  SensorError.swift
//  GlucoseDirect
//

import Foundation

struct SensorError: CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle

    init(timestamp: Date, error: SensorReadingError) {
        self.id = UUID()
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.error = error
    }

    init(id: UUID, timestamp: Date, error: SensorReadingError) {
        self.id = UUID()
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.error = error
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let error: SensorReadingError

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.toLocalTime())",
            "error: \(error.description)"
        ].joined(separator: ", ")
    }
}
