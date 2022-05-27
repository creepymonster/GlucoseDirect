//
//  CalibrationService.swift
//  LibreDirect
//

import Foundation

// MARK: - CalibrationService

class CalibrationService {
    // MARK: Internal

    func withMinuteChange(nextGlucose: Glucose, previousGlucose: Glucose? = nil) -> Glucose {
        guard let nextGlucoseValue = nextGlucose.calibratedGlucoseValue else {
            return nextGlucose
        }

        guard let previousGlucose = previousGlucose else {
            return nextGlucose
        }

        guard let previousGlucoseValue = previousGlucose.calibratedGlucoseValue else {
            return nextGlucose
        }

        return Glucose(
            id: nextGlucose.id,
            timestamp: nextGlucose.timestamp,
            minuteChange: minuteChange(previousTimestamp: previousGlucose.timestamp, previousGlucoseValue: previousGlucoseValue, nextTimestamp: nextGlucose.timestamp, nextGlucoseValue: nextGlucoseValue),
            initialGlucoseValue: nextGlucose.initialGlucoseValue,
            calibratedGlucoseValue: nextGlucose.calibratedGlucoseValue,
            type: nextGlucose.type,
            quality: nextGlucose.quality
        )
    }

    func withCalibration(customCalibration: [CustomCalibration], reading: SensorReading) -> Glucose {
        guard let glucoseValue = reading.glucoseValue else {
            return Glucose(id: reading.id, timestamp: reading.timestamp, quality: reading.quality)
        }

        guard !glucoseValue.isNaN else {
            return Glucose(id: reading.id, timestamp: reading.timestamp, quality: reading.quality)
        }

        guard !glucoseValue.isInfinite else {
            return Glucose(id: reading.id, timestamp: reading.timestamp, quality: reading.quality)
        }

        return Glucose(
            id: reading.id,
            timestamp: reading.timestamp,
            initialGlucoseValue: Int(glucoseValue),
            calibratedGlucoseValue: Int(calibration(customCalibration: customCalibration, glucoseValue: glucoseValue)),
            type: .cgm,
            quality: reading.quality
        )
    }

    // MARK: Private

    private func calibration(customCalibration: [CustomCalibration], glucoseValue: Double) -> Double {
        let calibratedGlucoseValue = customCalibration.calibrate(sensorGlucose: glucoseValue)

        if calibratedGlucoseValue.isNaN || calibratedGlucoseValue.isInfinite {
            return glucoseValue
        }

        return calibratedGlucoseValue
    }

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
