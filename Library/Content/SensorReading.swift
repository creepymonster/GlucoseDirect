//
//  SensorReading.swift
//  GlucoseDirect
//

import Foundation

// MARK: - SensorReading

class SensorReading: CustomStringConvertible, Codable {
    // MARK: Lifecycle

    private init(timestamp: Date, quality: SensorReadingQuality) {
        self.id = UUID()
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.glucoseValue = 0
        self.quality = quality
    }

    private init(timestamp: Date, glucoseValue: Double) {
        self.id = UUID()
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.glucoseValue = glucoseValue
        self.quality = .OK
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let glucoseValue: Double
    let quality: SensorReadingQuality

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.toLocalTime())",
            "glucoseValue: \(glucoseValue.description)",
            "quality: \(quality.description)"
        ].joined(separator: ", ")
    }
}

extension SensorReading {
    static func createGlucoseReading(timestamp: Date, glucoseValue: Double) -> SensorReading {
        return SensorReading(timestamp: timestamp, glucoseValue: glucoseValue)
    }

    static func createFaultyReading(timestamp: Date, quality: SensorReadingQuality) -> SensorReading {
        return SensorReading(timestamp: timestamp, quality: quality)
    }

    func calibrate(customCalibration: [CustomCalibration]) -> Glucose {
        if quality != .OK {
            return Glucose.faultySensorGlucose(timestamp: timestamp, quality: quality)
        }

        let calibratedGlucoseValue = Int(calibration(glucoseValue: glucoseValue, customCalibration: customCalibration))

        return Glucose.sensorGlucose(timestamp: timestamp, rawGlucoseValue: Int(glucoseValue), glucoseValue: calibratedGlucoseValue)
    }

    private func calibration(glucoseValue: Double, customCalibration: [CustomCalibration]) -> Double {
        let calibratedGlucoseValue = customCalibration.calibrate(sensorGlucose: glucoseValue)

        if calibratedGlucoseValue.isNaN || calibratedGlucoseValue.isInfinite {
            return glucoseValue
        }

        return calibratedGlucoseValue
    }
}
