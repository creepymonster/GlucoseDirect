//
//  SensorGlucose.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation

class SensorGlucose: CustomStringConvertible, Codable {
    let id: Int
    let timeStamp: Date
    let glucose: Int
    
    var lowerLimits: [Int] = [AppConfig.MinReadableGlucose]
    var upperLimits: [Int] = [AppConfig.MaxReadableGlucose]
    var minuteChange: Double = 0
    
    var trend: SensorTrend {
        get {
            return SensorTrend(slope: minuteChange)
        }
    }
    
    var glucoseFiltered: Int {
        get {
            if let lowerLimit = lowerLimits.max(), glucose < lowerLimit {
                return lowerLimit
            } else if let upperLimit = upperLimits.min(), glucose > upperLimit {
                return upperLimit
            }

            return glucose
        }
    }
    
    private let rawValue: Double?
    private let rawTemperature: Double?
    private let rawTemperatureAdjustment: Double?
    
    init(glucose: Int) {
        self.id = 0
        self.timeStamp = Date()
        self.glucose = glucose
        self.minuteChange = 0
        self.rawValue = nil
        self.rawTemperature = nil
        self.rawTemperatureAdjustment = nil
    }
    
    init(timeStamp: Date, glucose: Int) {
        self.id = 0
        self.timeStamp = timeStamp.rounded(on: 1, .minute)
        self.glucose = glucose
        self.minuteChange = 0
        self.rawValue = nil
        self.rawTemperature = nil
        self.rawTemperatureAdjustment = nil
    }

    init(id: Int, timeStamp: Date, glucose: Int, minuteChange: Double) {
        self.id = id
        self.timeStamp = timeStamp.rounded(on: 1, .minute)
        self.glucose = glucose
        self.minuteChange = minuteChange
        self.rawValue = nil
        self.rawTemperature = nil
        self.rawTemperatureAdjustment = nil
    }

    init(id: Int, timeStamp: Date, rawValue: Double, rawTemperature: Double, rawTemperatureAdjustment: Double, calibration: SensorCalibration) {
        self.id = id
        self.timeStamp = timeStamp.rounded(on: 1, .minute)
        self.rawValue = rawValue
        self.rawTemperature = rawTemperature
        self.rawTemperatureAdjustment = rawTemperatureAdjustment
        self.glucose = calibration.calibrate(rawValue: rawValue, rawTemperature: rawTemperature, rawTemperatureAdjustment: rawTemperatureAdjustment)
    }

    var description: String {
        return "\(timeStamp.localTime): \(glucoseFiltered.description) \(trend.description) (lowerLimits: \(lowerLimits), upperLimits: \(upperLimits))"
    }
}

fileprivate extension Sequence where Element: SensorGlucose {
    func sum() -> Double {
        return Double(self.compactMap { $0.glucose }.reduce(0, +))
    }
}
