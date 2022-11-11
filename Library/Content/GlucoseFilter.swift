//
//  GlucoseFilter.swift
//  GlucoseDirect
//

import Foundation

// MARK: - GlucoseFilter

class GlucoseFilter {
    // MARK: Internal

    func filter(glucoseValue: Int) -> Int {
        if let estimateValue = filter(glucoseValue: Double(glucoseValue)).toInteger() {
            return estimateValue
        }

        return glucoseValue
    }

    func filter(glucoseValue: Double) -> Double {
        if let kalmanFilter = kalmanFilter {
            return kalmanFilter.updateEstimate(glucoseValue) ?? glucoseValue
        }

        kalmanFilter = KalmanFilter(errMeasure: 0.5, errEstimate: 0.2, pNoise: 0.01, estimate: glucoseValue)
        return glucoseValue
    }

    // MARK: Private

    private let filterNoise: Double = 10
    private var kalmanFilter: KalmanFilter?
}

private class KalmanFilter {
    var errMeasure: Double
    var errEstimate: Double
    var q: Double
    var currentEstimate: Double
    var lastEstimate: Double
    var kalmanGain: Double
    
    init(errMeasure: Double, errEstimate: Double, pNoise: Double, estimate: Double) {
        self.errMeasure = errMeasure
        self.errEstimate = errEstimate
        self.q = pNoise
        self.currentEstimate = estimate
        self.lastEstimate = estimate
        self.kalmanGain = 0
    }
    
    func updateEstimate(_ measure: Double?) -> Double? {
        guard let measureValue = measure else {
            return nil
        }
        
        kalmanGain = errEstimate / (errEstimate + errMeasure)
        currentEstimate = lastEstimate + kalmanGain * (measureValue - lastEstimate)
        errEstimate = (1.0 - kalmanGain) * errEstimate + abs(lastEstimate - currentEstimate) * q
        lastEstimate = currentEstimate
        
        return currentEstimate
    }
    
    func setMeasurementError(_ errMeasure: Double) {
        self.errMeasure = errMeasure
    }
    
    func setEstimateError(_ errEst: Double) {
        self.errEstimate = errEst
    }
    
    func setProcessNoise(_ pNoise: Double) {
        self.q = pNoise
    }
    
    func getKalmanGain() -> Double {
        return self.kalmanGain
    }
    
    func getEstimateError() -> Double {
        return self.errEstimate
    }
}
