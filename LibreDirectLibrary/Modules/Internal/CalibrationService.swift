//
//  CalibrationService.swift
//  LibreDirect
//

import Foundation

// MARK: - CalibrationService

class CalibrationService {
    // MARK: Internal

    func calibrate(sensor: Sensor, nextReading: SensorReading, currentGlucose: Glucose? = nil) -> Glucose? {
        let initialGlucoseValue = nextReading.glucoseValue
        let customCalibratedGlucose = sensor.customCalibration.calibrate(sensorGlucose: initialGlucoseValue)

        var minuteChange: Double?

        if let currentGlucose = currentGlucose {
            minuteChange = calculateSlope(
                lastTimestamp: currentGlucose.timestamp,
                lastGlucoseValue: currentGlucose.glucoseValue,
                currentTimestamp: nextReading.timestamp,
                currentGlucoseValue: Int(customCalibratedGlucose)
            )
        }

        let currentGlucose = Glucose(
            id: nextReading.id,
            timestamp: nextReading.timestamp,
            minuteChange: minuteChange,
            initialGlucoseValue: Int(initialGlucoseValue),
            calibratedGlucoseValue: Int(customCalibratedGlucose),
            type: .cgm
        )

        return currentGlucose
    }

    // MARK: Private

    private func calculateSlope(lastTimestamp: Date, lastGlucoseValue: Int, currentTimestamp: Date, currentGlucoseValue: Int) -> Double {
        if lastTimestamp == currentTimestamp {
            return 0.0
        }

        let glucoseDiff = Double(currentGlucoseValue) - Double(lastGlucoseValue)
        let minutesDiff = calculateDiffInMinutes(old: lastTimestamp, new: currentTimestamp)

        return glucoseDiff / minutesDiff
    }

    private func calculateDiffInMinutes(old: Date, new: Date) -> Double {
        let diff = new.timeIntervalSince(old)
        return diff / 60
    }
}
