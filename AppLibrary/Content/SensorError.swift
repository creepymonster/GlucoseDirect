//
//  SensorError.swift
//  GlucoseDirect
//

import Foundation

// MARK: - SensorError

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

// MARK: Equatable

extension SensorError: Equatable {
    func isMinutly(ofMinutes: Int) -> Bool {
        let minutes = Calendar.current.component(.minute, from: timestamp)

        return minutes % ofMinutes == 0
    }

    static func == (lhs: SensorError, rhs: SensorError) -> Bool {
        lhs.id == rhs.id
    }
}
