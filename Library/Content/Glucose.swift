//
//  Glucose.swift
//  GlucoseDirect
//

import Foundation

// MARK: - Glucose

class Glucose: CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle

    private init(timestamp: Date, rawGlucoseValue: Int?, glucoseValue: Int?, minuteChange: Double?, type: GlucoseType) {
        self.id = UUID()
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.rawGlucoseValue = rawGlucoseValue
        self.uncheckedGlucoseValue = glucoseValue
        self.minuteChange = minuteChange
        self.type = type
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let minuteChange: Double?
    let rawGlucoseValue: Int?
    let type: GlucoseType
    let uncheckedGlucoseValue: Int?

    var glucoseValue: Int? {
        if let uncheckedGlucoseValue = uncheckedGlucoseValue {
            if uncheckedGlucoseValue <= DirectConfig.minReadableGlucose, type == .cgm {
                return DirectConfig.minReadableGlucose
            } else if uncheckedGlucoseValue >= DirectConfig.maxReadableGlucose, type == .cgm {
                return DirectConfig.maxReadableGlucose
            }

            return uncheckedGlucoseValue
        }

        return nil
    }

    var trend: SensorTrend {
        if let minuteChange = minuteChange {
            return SensorTrend(slope: minuteChange)
        }

        return .unknown
    }

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.toLocalTime())",
            "minuteChange: \(minuteChange?.description ?? "")",
            "rawGlucoseValue: \(rawGlucoseValue?.description ?? "-")",
            "glucoseValue: \(glucoseValue?.description ?? "-")",
            "type: \(type.localizedString)"
        ].joined(separator: ", ")
    }
}

extension Glucose {
    static func createSensorGlucose(timestamp: Date, rawGlucoseValue: Int, minuteChange: Double?) -> Glucose {
        return Glucose(timestamp: timestamp, rawGlucoseValue: rawGlucoseValue, glucoseValue: nil, minuteChange: minuteChange, type: .cgm)
    }

    static func createSensorGlucose(timestamp: Date, rawGlucoseValue: Int, glucoseValue: Int, minuteChange: Double?) -> Glucose {
        if glucoseValue <= DirectConfig.minReadableGlucose {
            return Glucose(timestamp: timestamp, rawGlucoseValue: rawGlucoseValue, glucoseValue: DirectConfig.minReadableGlucose, minuteChange: minuteChange, type: .cgm)
        } else if glucoseValue >= DirectConfig.maxReadableGlucose {
            return Glucose(timestamp: timestamp, rawGlucoseValue: rawGlucoseValue, glucoseValue: DirectConfig.maxReadableGlucose, minuteChange: minuteChange, type: .cgm)
        }

        return Glucose(timestamp: timestamp, rawGlucoseValue: rawGlucoseValue, glucoseValue: glucoseValue, minuteChange: minuteChange, type: .cgm)
    }

    static func createBloodGlucose(timestamp: Date, glucoseValue: Int) -> Glucose {
        return Glucose(timestamp: timestamp, rawGlucoseValue: glucoseValue, glucoseValue: glucoseValue, minuteChange: nil, type: .bgm)
    }

    static func createFaultyGlucose(timestamp: Date, quality: SensorReadingQuality) -> Glucose {
        return Glucose(timestamp: timestamp, rawGlucoseValue: nil, glucoseValue: nil, minuteChange: nil, type: .faulty(quality))
    }

    var isSensorGlucose: Bool {
        type == .cgm
    }

    var isBloodGlucose: Bool {
        type == .bgm
    }

    var isFaultyGlucose: Bool {
        if case .faulty = type {
            return true
        }

        return false
    }

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

    func populateChange(previousGlucose: Glucose? = nil) -> Glucose {
        guard let rawGlucoseValue = rawGlucoseValue, let glucoseValue = glucoseValue else {
            return self
        }

        guard let previousGlucose = previousGlucose else {
            return self
        }

        guard let previousGlucoseValue = previousGlucose.glucoseValue else {
            return self
        }

        return Glucose.createSensorGlucose(timestamp: timestamp, rawGlucoseValue: rawGlucoseValue, glucoseValue: glucoseValue, minuteChange: minuteChange(previousTimestamp: previousGlucose.timestamp, previousGlucoseValue: previousGlucoseValue, nextTimestamp: timestamp, nextGlucoseValue: glucoseValue))
    }

    // MARK: Private

    private func minuteChange(previousTimestamp: Date, previousGlucoseValue: Int, nextTimestamp: Date, nextGlucoseValue: Int) -> Double {
        if previousTimestamp == nextTimestamp {
            return 0.0
        }

        let glucoseDiff = Double(nextGlucoseValue) - Double(previousGlucoseValue)
        let minutesDiff = calculateDiffInMinutes(previousTimestamp: previousTimestamp, nextTimestamp: nextTimestamp)

        return glucoseDiff / minutesDiff
    }

    private func calculateDiffInMinutes(previousTimestamp: Date, nextTimestamp: Date) -> Double {
        let diff = nextTimestamp.timeIntervalSince(previousTimestamp)
        return diff / 60
    }
}

// MARK: Equatable

extension Glucose: Equatable {
    static func == (lhs: Glucose, rhs: Glucose) -> Bool {
        lhs.id == rhs.id
    }
}
