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
        self.readGlucoseValue = glucoseValue
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let readGlucoseValue: Double

    var glucoseValue: Double {
        let minReadableGlucose = Double(AppConfig.MinReadableGlucose)
        let maxReadableGlucose = Double(AppConfig.MaxReadableGlucose)

        if readGlucoseValue < minReadableGlucose {
            return minReadableGlucose
        } else if readGlucoseValue > maxReadableGlucose {
            return maxReadableGlucose
        }

        return readGlucoseValue
    }

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.localTime)",
            "glucoseValue: \(glucoseValue.description)"
        ].joined(separator: ", ")
    }
}
