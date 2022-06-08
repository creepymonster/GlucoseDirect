//
//  Glucose.swift
//  GlucoseDirect
//

import Foundation

// MARK: - Glucose

final class Glucose: CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle

    init(id: UUID, timestamp: Date, quality: GlucoseQuality) {
        self.id = id
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.minuteChange = nil

        self.calibratedGlucoseValue = nil
        self.initialGlucoseValue = nil

        self.type = .none
        self.quality = quality
    }

    init(id: UUID, timestamp: Date, glucose: Int, type: GlucoseValueType, quality: GlucoseQuality = .OK) {
        self.id = id
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.minuteChange = nil

        if quality == .OK {
            self.calibratedGlucoseValue = glucose
            self.initialGlucoseValue = glucose
        } else {
            self.calibratedGlucoseValue = nil
            self.initialGlucoseValue = nil
        }

        self.type = type
        self.quality = quality
    }

    init(id: UUID, timestamp: Date, initialGlucoseValue: Int?, calibratedGlucoseValue: Int?, type: GlucoseValueType, quality: GlucoseQuality = .OK) {
        self.id = id
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.minuteChange = nil

        if quality == .OK {
            self.initialGlucoseValue = initialGlucoseValue
            self.calibratedGlucoseValue = calibratedGlucoseValue
        } else {
            self.calibratedGlucoseValue = nil
            self.initialGlucoseValue = nil
        }

        self.type = type
        self.quality = quality
    }

    init(id: UUID, timestamp: Date, minuteChange: Double?, initialGlucoseValue: Int?, calibratedGlucoseValue: Int?, type: GlucoseValueType, quality: GlucoseQuality = .OK) {
        self.id = id
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.minuteChange = minuteChange

        if quality == .OK {
            self.initialGlucoseValue = initialGlucoseValue
            self.calibratedGlucoseValue = calibratedGlucoseValue
        } else {
            self.calibratedGlucoseValue = nil
            self.initialGlucoseValue = nil
        }

        self.type = type
        self.quality = quality
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let minuteChange: Double?
    let initialGlucoseValue: Int?
    let calibratedGlucoseValue: Int?
    let type: GlucoseValueType
    let quality: GlucoseQuality

    var trend: SensorTrend {
        if let minuteChange = minuteChange {
            return SensorTrend(slope: minuteChange)
        }

        return .unknown
    }

    var glucoseValue: Int? {
        guard let calibratedGlucoseValue = calibratedGlucoseValue else {
            return nil
        }

        if calibratedGlucoseValue <= DirectConfig.minReadableGlucose {
            return DirectConfig.minReadableGlucose
        } else if calibratedGlucoseValue >= DirectConfig.maxReadableGlucose {
            return DirectConfig.maxReadableGlucose
        }

        return calibratedGlucoseValue
    }

    var isHIGH: Bool {
        guard let calibratedGlucoseValue = calibratedGlucoseValue else {
            return false
        }

        return calibratedGlucoseValue >= DirectConfig.maxReadableGlucose
    }

    var isLOW: Bool {
        guard let calibratedGlucoseValue = calibratedGlucoseValue else {
            return false
        }

        return calibratedGlucoseValue <= DirectConfig.minReadableGlucose
    }

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.toLocalTime())",
            "minuteChange: \(minuteChange?.description ?? "")",
            "factoryCalibratedGlucoseValue: \(initialGlucoseValue?.description ?? "-")",
            "calibratedGlucoseValue: \(calibratedGlucoseValue?.description ?? "-")",
            "glucoseValue: \(glucoseValue?.description ?? "-")",
            "type: \(type.rawValue)",
            "quality: \(quality.rawValue)"
        ].joined(separator: ", ")
    }
}

extension Glucose {
    var is5Minutely: Bool {
        let minutes = Calendar.current.component(.minute, from: timestamp)

        return minutes % 5 == 0
    }

    var is10Minutely: Bool {
        let minutes = Calendar.current.component(.minute, from: timestamp)

        return minutes % 10 == 0
    }

    var is15Minutely: Bool {
        let minutes = Calendar.current.component(.minute, from: timestamp)

        return minutes % 15 == 0
    }
}

// MARK: Equatable

extension Glucose: Equatable {
    static func == (lhs: Glucose, rhs: Glucose) -> Bool {
        lhs.timestamp == rhs.timestamp
    }
}
