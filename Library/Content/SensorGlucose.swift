//
//  SensorGlucose.swift
//  GlucoseDirect
//
//  https://www.jaeb.org/gmi/
//  GMI(%) = 3.31 + 0.02392 x [mean glucose in mg/dL]
//  GMI(mmol/mol) = 12.71 + 4.70587 x [mean glucose in mmol/L]
//

import Foundation

// MARK: - GlucoseStatistics

struct GlucoseStatistics: Codable {
    let readings: Int
    let fromTimestamp: Date
    let toTimestamp: Date
    let gmi: Double
    let avg: Double
    let tbr: Double
    let tar: Double
    let variance: Double
    let days: Int

    var tir: Double {
        100.0 - tor
    }

    var tor: Double {
        tbr + tar
    }

    var stdev: Double {
        sqrt(variance)
    }

    var cv: Double {
        100 * stdev / avg
    }
}

// MARK: - SensorGlucose

struct SensorGlucose: Glucose, CustomStringConvertible, Codable, Identifiable, Hashable {
    // MARK: Lifecycle

    init(glucoseValue: Int, minuteChange: Double? = nil) {
        let roundedTimestamp = Date().toRounded(on: 1, .minute)

        self.id = UUID()
        self.timestamp = roundedTimestamp
        self.rawGlucoseValue = glucoseValue
        self.intGlucoseValue = glucoseValue
        self.minuteChange = minuteChange
        self.timegroup = roundedTimestamp.toRounded(on: DirectConfig.timegroupRounding, .minute)
    }

    init(timestamp: Date, rawGlucoseValue: Int, intGlucoseValue: Int, minuteChange: Double? = nil) {
        let roundedTimestamp = timestamp.toRounded(on: 1, .minute)

        self.id = UUID()
        self.timestamp = roundedTimestamp
        self.rawGlucoseValue = rawGlucoseValue
        self.intGlucoseValue = intGlucoseValue
        self.minuteChange = minuteChange
        self.timegroup = roundedTimestamp.toRounded(on: DirectConfig.timegroupRounding, .minute)
    }

    init(id: UUID, timestamp: Date, rawGlucoseValue: Int, intGlucoseValue: Int, minuteChange: Double? = nil) {
        let roundedTimestamp = timestamp.toRounded(on: 1, .minute)

        self.id = id
        self.timestamp = roundedTimestamp
        self.rawGlucoseValue = rawGlucoseValue
        self.intGlucoseValue = intGlucoseValue
        self.minuteChange = minuteChange
        self.timegroup = roundedTimestamp.toRounded(on: DirectConfig.timegroupRounding, .minute)
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let minuteChange: Double?
    let rawGlucoseValue: Int
    let intGlucoseValue: Int
    let timegroup: Date

    var glucoseValue: Int {
        if intGlucoseValue <= DirectConfig.minReadableGlucose {
            return DirectConfig.minReadableGlucose
        } else if intGlucoseValue >= DirectConfig.maxReadableGlucose {
            return DirectConfig.maxReadableGlucose
        }

        return intGlucoseValue
    }

    var trend: SensorTrend {
        if let minuteChange = minuteChange {
            return SensorTrend(slope: minuteChange)
        }

        return .unknown
    }

    var description: String {
        "{ id: \(id), timestamp: \(timestamp.toLocalTime()), minuteChange: \(minuteChange?.description ?? ""), rawGlucoseValue: \(rawGlucoseValue.description), glucoseValue: \(glucoseValue.description) }"
    }
}

extension SensorGlucose {
    func populateChange(previousGlucose: SensorGlucose? = nil) -> SensorGlucose {
        guard let previousGlucose = previousGlucose else {
            return self
        }

        return SensorGlucose(id: id, timestamp: timestamp, rawGlucoseValue: rawGlucoseValue, intGlucoseValue: glucoseValue, minuteChange: minuteChange(previousTimestamp: previousGlucose.timestamp, previousGlucoseValue: previousGlucose.glucoseValue, nextTimestamp: timestamp, nextGlucoseValue: glucoseValue))
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

extension Array where Element == SensorGlucose {
    var doubleValues: [Double] {
        map {
            $0.glucoseValue
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
