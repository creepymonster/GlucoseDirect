//
//  CustomCalibration.swift
//  LibreDirect
//
//  Special thanks to: ivalko, raywenderlich
//

import Foundation

// MARK: - CustomCalibration

struct CustomCalibration: Codable, Equatable, Identifiable {
    // MARK: Lifecycle

    init(x: Int, y: Int) {
        self.id = UUID()
        self.timestamp = Date()
        self.x = Double(x)
        self.y = Double(y)
    }

    init(x: Double, y: Double) {
        self.id = UUID()
        self.timestamp = Date()
        self.x = x
        self.y = y
    }

    // MARK: Internal

    static let zero = CustomCalibration(x: 0, y: 0)

    let id: UUID
    let timestamp: Date
    let x: Double
    let y: Double

    var description: String {
        "\(x) = \(y)"
    }
}

extension Array where Element == CustomCalibration {
    private enum Config {
        static let minSlope = 0.8
        static let maxSlope = 1.25
        static let minIntercept = -100.0
        static let maxIntercept = 100.0
    }

    func calibrate(sensorGlucose: Double) -> Double {
        let calibrated = linearRegression(sensorGlucose)
        return calibrated
    }

    var slope: Double {
        guard count >= 2 else {
            return 1
        }

        let xs = map(\.x)
        let ys = map(\.y)
        let sum1 = average(multiply(xs, ys)) - average(xs) * average(ys)

        let sum2 = average(multiply(xs, xs)) - pow(average(xs), 2)
        if sum2 == 0 {
            return 1
        }

        let slope = sum1 / sum2

        return Swift.min(Swift.max(slope, Config.minSlope), Config.maxSlope)
    }

    var intercept: Double {
        guard count >= 1 else {
            return 0
        }

        let xs = map(\.x)
        let ys = map(\.y)

        let intercept = average(ys) - slope * average(xs)

        return Swift.min(Swift.max(intercept, Config.minIntercept), Config.maxIntercept)
    }

    var description: String {
        [
            "slope: \(slope.description)",
            "intercept: \(intercept.description)",
        ].joined(separator: ", ")
    }

    // MARK: Private

    private var minReadableGlucose: Double {
        Double(AppConfig.minReadableGlucose)
    }

    private var maxReadableGlucose: Double {
        Double(AppConfig.maxReadableGlucose)
    }

    private func average(_ input: [Double]) -> Double {
        input.reduce(0, +) / Double(input.count)
    }

    private func multiply(_ a: [Double], _ b: [Double]) -> [Double] {
        zip(a, b).map(*)
    }

    private func linearRegression(_ x: Double) -> Double {
        let result = intercept + slope * x

        if result < minReadableGlucose {
            return minReadableGlucose
        }

        if result > maxReadableGlucose {
            return maxReadableGlucose
        }

        return result
    }
}
