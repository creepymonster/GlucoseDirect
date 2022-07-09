//
//  SensorReading.swift
//  GlucoseDirect
//

import Foundation

// MARK: - SensorReading

class SensorReading: CustomStringConvertible, Codable {
    // MARK: Lifecycle

    private init(timestamp: Date, quality: SensorReadingError) {
        self.id = UUID()
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.glucoseValue = 0
        self.error = quality
    }

    private init(timestamp: Date, glucoseValue: Double) {
        self.id = UUID()
        self.timestamp = timestamp.toRounded(on: 1, .minute)
        self.glucoseValue = glucoseValue
        self.error = .OK
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let glucoseValue: Double
    let error: SensorReadingError

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.toLocalTime())",
            "glucoseValue: \(glucoseValue.description)",
            "quality: \(error.description)"
        ].joined(separator: ", ")
    }
}

extension SensorReading {
    static func createGlucoseReading(timestamp: Date, glucoseValue: Double) -> SensorReading {
        return SensorReading(timestamp: timestamp, glucoseValue: glucoseValue)
    }

    static func createFaultyReading(timestamp: Date, quality: SensorReadingError) -> SensorReading {
        return SensorReading(timestamp: timestamp, quality: quality)
    }

    func calibrate(customCalibration: [CustomCalibration]) -> SensorGlucose? {
        guard error == .OK else {
            return nil
        }

        let calibratedGlucoseValue = Int(calibration(glucoseValue: glucoseValue, customCalibration: customCalibration))

        return SensorGlucose(id: id, timestamp: timestamp, rawGlucoseValue: Int(glucoseValue), intGlucoseValue: calibratedGlucoseValue)
    }

    private func calibration(glucoseValue: Double, customCalibration: [CustomCalibration]) -> Double {
        let calibratedGlucoseValue = customCalibration.calibrate(sensorGlucose: glucoseValue)

        if calibratedGlucoseValue.isNaN || calibratedGlucoseValue.isInfinite {
            return glucoseValue
        }

        return calibratedGlucoseValue
    }
}
