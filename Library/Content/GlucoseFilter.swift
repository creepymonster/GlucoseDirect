//
//  GlucoseFilter.swift
//  GlucoseDirect
//

import Foundation

// MARK: - GlucoseFilter

class GlucoseFilter {
    // MARK: Internal

    func filter(glucoseValue: Int) -> Double {
        return filter(glucoseValue: Double(glucoseValue))
    }

    func filter(glucoseValue: Double) -> Double {
        if let kalmanFilter = kalmanFilter {
            return kalmanFilter.filter(glucoseValue)
        }

        kalmanFilter = KalmanFilter(processNoise: 5, measurementNoise: 50, stateVector: 1, controlVector: 1, measurementVector: 1)
        return glucoseValue
    }

    // MARK: Private

    private let filterNoise: Double = 10
    private var kalmanFilter: KalmanFilter?
}

private class KalmanFilter {
    init(processNoise: Double, measurementNoise: Double, stateVector: Double, controlVector: Double, measurementVector: Double) {
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
        
        self.stateVector = stateVector
        self.controlVector = controlVector
        self.measurementVector = measurementVector
    }
    
    // MARK: Internal
    func filter(_ measurement: Double, _ control: Double = 0) -> Double {
        if self.isFirst {
            isFirst = false
            
            x = (1 / controlVector) * measurement
            cov = (1 / controlVector) * measurementNoise * (1 / controlVector)
        } else {
            // Compute prediction
            let predX = predict(control)
            let predCov = uncertainty()
            
            // Kalman gain
            let K = predCov * controlVector * (1 / ((controlVector * predCov * controlVector) + measurementNoise))
            
            // Correction
            x = predX + K * (measurement - (controlVector * predX))
            cov = predCov - (K * controlVector * predCov)
        }
        
        return x
    }
    
    // MARK: Private
    private let processNoise: Double
    private let measurementNoise: Double
    private let stateVector: Double
    private let measurementVector: Double
    private let controlVector: Double
    
    private var isFirst = true
    private var cov: Double = 0
    private var x: Double = 0
    
    private func predict(_ control: Double = 0) -> Double {
        return (stateVector * x) + (measurementVector * control)
    }
    
    private func uncertainty() -> Double {
        return ((stateVector * cov) * stateVector) + processNoise
    }
}
