//
//  CalibrationService.swift
//  LibreDirect
//

import Foundation

// MARK: - CalibrationService

class CalibrationService {
    // MARK: Internal

    func calibrate(sensor: Sensor, nextReading: SensorReading, currentGlucose: Glucose? = nil) -> Glucose {
        if let nextGlucoseValue = nextReading.glucoseValue, nextReading.quality == .OK {
            let nextCalibratedGlucoseValue = sensor.customCalibration.calibrate(sensorGlucose: nextGlucoseValue)
            var nextMinuteChange: Double?

            if let currentGlucose = currentGlucose, let currentGlucoseValue = currentGlucose.glucoseValue {
                nextMinuteChange = calculateSlope(
                    currentTimestamp: currentGlucose.timestamp,
                    currentGlucoseValue: currentGlucoseValue,
                    nextTimestamp: nextReading.timestamp,
                    nextGlucoseValue: Int(nextCalibratedGlucoseValue)
                )
            }

            let nextGlucose = Glucose(
                id: nextReading.id,
                timestamp: nextReading.timestamp,
                minuteChange: nextMinuteChange,
                initialGlucoseValue: Int(nextGlucoseValue),
                calibratedGlucoseValue: Int(nextCalibratedGlucoseValue),
                type: .cgm,
                quality: nextReading.quality
            )

            return nextGlucose
        }
        
        return Glucose(id: nextReading.id, timestamp: nextReading.timestamp, type: .none, quality: nextReading.quality)
    }

    // MARK: Private

    private func calculateSlope(currentTimestamp: Date, currentGlucoseValue: Int, nextTimestamp: Date, nextGlucoseValue: Int) -> Double {
        if currentTimestamp == nextTimestamp {
            return 0.0
        }

        let glucoseDiff = Double(nextGlucoseValue) - Double(currentGlucoseValue)
        let minutesDiff = calculateDiffInMinutes(old: currentTimestamp, new: nextTimestamp)

        return glucoseDiff / minutesDiff
    }

    private func calculateDiffInMinutes(old: Date, new: Date) -> Double {
        let diff = new.timeIntervalSince(old)
        return diff / 60
    }
}
