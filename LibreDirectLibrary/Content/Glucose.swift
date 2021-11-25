//
//  Glucose.swift
//  LibreDirect
//

import Foundation

// MARK: - Glucose

final class Glucose: CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle

    init(glucose: Int) {
        self.id = UUID()
        self.timestamp = Date()

        self.minuteChange = 0
        self.initialGlucoseValue = glucose
        self.calibratedGlucoseValue = glucose
        self.type = .cgm
    }

    init(id: UUID, timestamp: Date, glucose: Int, type: GlucoseValueType) {
        self.id = id
        self.timestamp = timestamp.rounded(on: 1, .minute)

        self.minuteChange = 0
        self.calibratedGlucoseValue = glucose
        self.initialGlucoseValue = glucose
        self.type = type
    }

    init(id: UUID, timestamp: Date, glucose: Int, minuteChange: Double, type: GlucoseValueType) {
        self.id = id
        self.timestamp = timestamp.rounded(on: 1, .minute)

        self.minuteChange = minuteChange
        self.calibratedGlucoseValue = glucose
        self.initialGlucoseValue = glucose
        self.type = type
    }

    init(id: UUID, timestamp: Date, minuteChange: Double?, initialGlucoseValue: Int, calibratedGlucoseValue: Int, type: GlucoseValueType) {
        self.id = id
        self.timestamp = timestamp.rounded(on: 1, .minute)

        self.minuteChange = minuteChange
        self.initialGlucoseValue = initialGlucoseValue
        self.calibratedGlucoseValue = calibratedGlucoseValue
        self.type = type
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let minuteChange: Double?
    let initialGlucoseValue: Int
    let calibratedGlucoseValue: Int
    let type: GlucoseValueType

    var trend: SensorTrend {
        if let minuteChange = minuteChange {
            return SensorTrend(slope: minuteChange)
        }

        return .unknown
    }

    var glucoseValue: Int {
        if calibratedGlucoseValue < AppConfig.MinReadableGlucose {
            return AppConfig.MinReadableGlucose
        } else if calibratedGlucoseValue > AppConfig.MaxReadableGlucose {
            return AppConfig.MaxReadableGlucose
        }

        return calibratedGlucoseValue
    }

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.localTime)",
            "minuteChange: \(minuteChange?.description ?? "")",
            "factoryCalibratedGlucoseValue: \(initialGlucoseValue.description)",
            "calibratedGlucoseValue: \(calibratedGlucoseValue.description)",
            "glucoseValue: \(glucoseValue.description)"
        ].joined(separator: ", ")
    }
}

extension Glucose {
    var is5Minutely: Bool {
        let minutes = Calendar.current.component(.minute, from: timestamp)

        return minutes % 5 == 0
    }
}
