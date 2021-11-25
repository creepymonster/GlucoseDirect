//
//  SensorCalibration.swift
//  LibreDirect
//

import Foundation

// MARK: - SensorCalibration

protocol SensorCalibration {
    func calibrate(rawValue: Double, rawTemperature: Double, rawTemperatureAdjustment: Double) -> Double
}
