//
//  Glucose.swift
//  GlucoseDirect
//

import Foundation

// MARK: - Glucose

struct Glucose: CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle

    init(timestamp: Date, rawGlucoseValue: Int?, intGlucoseValue: Int?, minuteChange: Double?, type: GlucoseType) {
        self.id = UUID()
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.rawGlucoseValue = rawGlucoseValue
        self.intGlucoseValue = intGlucoseValue
        self.minuteChange = minuteChange
        self.type = type
    }

    init(id: UUID, timestamp: Date, rawGlucoseValue: Int?, intGlucoseValue: Int?, minuteChange: Double?, type: GlucoseType) {
        self.id = id
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.rawGlucoseValue = rawGlucoseValue
        self.intGlucoseValue = intGlucoseValue
        self.minuteChange = minuteChange
        self.type = type
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let minuteChange: Double?
    let rawGlucoseValue: Int?
    let type: GlucoseType
    let intGlucoseValue: Int?

    var glucoseValue: Int? {
        if let intGlucoseValue = intGlucoseValue {
            if intGlucoseValue <= DirectConfig.minReadableGlucose, isSensorGlucose {
                return DirectConfig.minReadableGlucose
            } else if intGlucoseValue >= DirectConfig.maxReadableGlucose, isSensorGlucose {
                return DirectConfig.maxReadableGlucose
            }

            return intGlucoseValue
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
    static func sensorGlucose(timestamp: Date, rawGlucoseValue: Int, minuteChange: Double? = nil) -> Glucose {
        return Glucose(timestamp: timestamp, rawGlucoseValue: rawGlucoseValue, intGlucoseValue: nil, minuteChange: minuteChange, type: .cgm)
    }

    static func sensorGlucose(timestamp: Date, glucoseValue: Int, minuteChange: Double? = nil) -> Glucose {
        return Glucose(timestamp: timestamp, rawGlucoseValue: glucoseValue, intGlucoseValue: glucoseValue, minuteChange: minuteChange, type: .cgm)
    }

    static func sensorGlucose(timestamp: Date, rawGlucoseValue: Int, glucoseValue: Int, minuteChange: Double? = nil) -> Glucose {
        return Glucose(timestamp: timestamp, rawGlucoseValue: rawGlucoseValue, intGlucoseValue: glucoseValue, minuteChange: minuteChange, type: .cgm)
    }

    static func bloodGlucose(timestamp: Date, glucoseValue: Int) -> Glucose {
        return Glucose(timestamp: timestamp, rawGlucoseValue: glucoseValue, intGlucoseValue: glucoseValue, minuteChange: nil, type: .bgm)
    }

    static func faultySensorGlucose(timestamp: Date, quality: SensorReadingQuality) -> Glucose {
        return Glucose(timestamp: timestamp, rawGlucoseValue: nil, intGlucoseValue: nil, minuteChange: nil, type: .faulty)
    }

    var isSensorGlucose: Bool {
        type == .cgm
    }

    var isBloodGlucose: Bool {
        type == .bgm
    }

    var isFaultyGlucose: Bool {
        type == .faulty
    }

    func isMinutly(ofMinutes: Int) -> Bool {
        let minutes = Calendar.current.component(.minute, from: timestamp)

        return minutes % ofMinutes == 0
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

        return Glucose.sensorGlucose(timestamp: timestamp, rawGlucoseValue: rawGlucoseValue, glucoseValue: glucoseValue, minuteChange: minuteChange(previousTimestamp: previousGlucose.timestamp, previousGlucoseValue: previousGlucoseValue, nextTimestamp: timestamp, nextGlucoseValue: glucoseValue))
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

extension Array where Element == Glucose {
    var doubleValues: [Double] {
        map {
            $0.glucoseValue
        }.compactMap {
            $0
        }.map {
            Double($0)
        }
    }

    var stdev: Double {
        let glucoseValues = doubleValues

        let length = Double(glucoseValues.count)
        let avg = glucoseValues.reduce(0, +) / length
        let sumOfSquaredAvgDiff = glucoseValues.map { pow($0 - avg, 2.0) }.reduce(0) { $0 + $1 }

        return sqrt(sumOfSquaredAvgDiff / (length - 1))
    }
}
