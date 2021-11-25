//
//  FilteringService.swift
//  LibreDirect
//

import Foundation

// MARK: - FilteringService

class FilteringService {
    // MARK: Internal

    func test(unfiltered: Double) {
        let filtered = self.filter.filter(z: unfiltered)

        Log.info("KalmanFilter: \(unfiltered.description) \(filtered.description)")
    }

    // MARK: Private

    private let filter = KalmanFilter()
}

// MARK: - KalmanFilter

private class KalmanFilter {
    // MARK: Internal

    func filter(z: Double, u: Double = 0) -> Double {
        if self.isFirst {
            self.isFirst = false

            self.x = (1 / self.C) * z
            self.cov = (1 / self.C) * self.Q * (1 / self.C)
        } else {
            // Compute prediction
            let predX = self.predict(u)
            let predCov = self.uncertainty()

            // Kalman gain
            let K = predCov * self.C * (1 / ((self.C * predCov * self.C) + self.Q))

            // Correction
            self.x = predX + K * (z - (self.C * predX))
            self.cov = predCov - (K * self.C * predCov)
        }

        return self.x
    }

    // MARK: Private

    private let R: Double = 1
    private let Q: Double = 1
    private let A: Double = 1
    private let B: Double = 0
    private let C: Double = 1

    private var isFirst = true
    private var cov: Double = 0
    private var x: Double = 0

    private func predict(_ u: Double = 0) -> Double {
        return (self.A * self.x) + (self.B * u)
    }

    private func uncertainty() -> Double {
        return ((self.A * self.cov) * self.A) + self.R
    }
}
