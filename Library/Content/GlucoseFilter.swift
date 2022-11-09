//
//  GlucoseFilter.swift
//  GlucoseDirect
//

import Foundation

// MARK: - GlucoseFilter

class GlucoseFilter {
    // MARK: Internal

    func filter(glucoseValue: Int) -> Int {
        if let intValue = filter(glucoseValue: Double(glucoseValue)).toInteger() {
            return intValue
        }

        return glucoseValue
    }

    func filter(glucoseValue: Double) -> Double {
        if let kalmanFilter = kalmanFilter {
            let predict = kalmanFilter.predict(stateTransitionModel: 1, controlInputModel: 0, controlVector: 0, covarianceOfProcessNoise: filterNoise)
            let update = predict.update(measurement: glucoseValue, observationModel: 1, covarienceOfObservationNoise: filterNoise)

            self.kalmanFilter = update
            return update.stateEstimatePrior
        }

        kalmanFilter = KalmanFilter(stateEstimatePrior: glucoseValue, errorCovariancePrior: filterNoise)
        return glucoseValue
    }

    // MARK: Private

    private let filterNoise: Double = 10
    private var kalmanFilter: KalmanFilter<Double>?
}

// MARK: - Double + KalmanInput

extension Double: KalmanInput {
    public var transposed: Double { self }
    public var inversed: Double { 1 / self }
    public var additionToUnit: Double { 1 - self }
}

// MARK: - KalmanInput

private protocol KalmanInput {
    var transposed: Self { get }
    var inversed: Self { get }
    var additionToUnit: Self { get }

    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
}

// MARK: - KalmanFilterType

private protocol KalmanFilterType {
    associatedtype Input: KalmanInput

    var stateEstimatePrior: Input { get }
    var errorCovariancePrior: Input { get }

    func predict(stateTransitionModel: Input, controlInputModel: Input, controlVector: Input, covarianceOfProcessNoise: Input) -> Self
    func update(measurement: Input, observationModel: Input, covarienceOfObservationNoise: Input) -> Self
}

// MARK: - KalmanFilter

private struct KalmanFilter<Type: KalmanInput>: KalmanFilterType {
    // MARK: Lifecycle

    init(stateEstimatePrior: Type, errorCovariancePrior: Type) {
        self.stateEstimatePrior = stateEstimatePrior
        self.errorCovariancePrior = errorCovariancePrior
    }

    // MARK: Internal

    /// x̂_k|k-1
    let stateEstimatePrior: Type

    /// P_k|k-1
    let errorCovariancePrior: Type

    /**
     Predict step in Kalman filter.
     - parameter stateTransitionModel: F_k
     - parameter controlInputModel: B_k
     - parameter controlVector: u_k
     - parameter covarianceOfProcessNoise: Q_k

     - returns: Another instance of Kalman filter with predicted x̂_k and P_k
     */
    func predict(stateTransitionModel: Type, controlInputModel: Type, controlVector: Type, covarianceOfProcessNoise: Type) -> KalmanFilter {
        // x̂_k|k-1 = F_k * x̂_k-1|k-1 + B_k * u_k
        let predictedStateEstimate = stateTransitionModel * stateEstimatePrior + controlInputModel * controlVector

        // P_k|k-1 = F_k * P_k-1|k-1 * F_k^t + Q_k
        let predictedEstimateCovariance = stateTransitionModel * errorCovariancePrior * stateTransitionModel.transposed + covarianceOfProcessNoise

        return KalmanFilter(stateEstimatePrior: predictedStateEstimate, errorCovariancePrior: predictedEstimateCovariance)
    }

    /**
     Update step in Kalman filter. We update our prediction with the measurements that we make
     - parameter measurement: z_k
     - parameter observationModel: H_k
     - parameter covarienceOfObservationNoise: R_k

     - returns: Updated with the measurements version of Kalman filter with new x̂_k and P_k
     */
    func update(measurement: Type, observationModel: Type, covarienceOfObservationNoise: Type) -> KalmanFilter {
        // H_k^t transposed. We cache it improve performance
        let observationModelTransposed = observationModel.transposed

        // ỹ_k = z_k - H_k * x̂_k|k-1
        let measurementResidual = measurement - observationModel * stateEstimatePrior

        // S_k = H_k * P_k|k-1 * H_k^t + R_k
        let residualCovariance = observationModel * errorCovariancePrior * observationModelTransposed + covarienceOfObservationNoise

        // K_k = P_k|k-1 * H_k^t * S_k^-1
        let kalmanGain = errorCovariancePrior * observationModelTransposed * residualCovariance.inversed

        // x̂_k|k = x̂_k|k-1 + K_k * ỹ_k
        let posterioriStateEstimate = stateEstimatePrior + kalmanGain * measurementResidual

        // P_k|k = (I - K_k * H_k) * P_k|k-1
        let posterioriEstimateCovariance = (kalmanGain * observationModel).additionToUnit * errorCovariancePrior

        return KalmanFilter(stateEstimatePrior: posterioriStateEstimate, errorCovariancePrior: posterioriEstimateCovariance)
    }
}
