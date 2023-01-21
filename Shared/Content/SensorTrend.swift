//
//  SensorTrend.swift
//  GlucoseDirect
//

import Foundation

// MARK: - SensorTrend

enum SensorTrend: String, Codable {
    case rapidlyRising = "↑↑"
    case fastRising = "↑"
    case rising = "↗︎"
    case constant = "→"
    case falling = "↘︎"
    case fastFalling = "↓"
    case rapidlyFalling = "↓↓"
    case unknown = "?"

    // MARK: Lifecycle

    init() {
        self = .unknown
    }

    init(slope: Double) {
        self = translateSlope(slope: slope)
    }

    // MARK: Internal

    var description: String {
        self.rawValue
    }
}

extension SensorTrend {
    func toNightscoutTrend() -> Int {
        switch self {
        case .rapidlyRising:
            return 1
        case .fastRising:
            return 2
        case .rising:
            return 3
        case .constant:
            return 4
        case .falling:
            return 5
        case .fastFalling:
            return 6
        case .rapidlyFalling:
            return 7
        case .unknown:
            return 0
        }
    }

    func toNightscoutDirection() -> String {
        switch self {
        case .rapidlyRising:
            return "DoubleUp"
        case .fastRising:
            return "SingleUp"
        case .rising:
            return "FortyFiveUp"
        case .constant:
            return "Flat"
        case .falling:
            return "FortyFiveDown"
        case .fastFalling:
            return "SingleDown"
        case .rapidlyFalling:
            return "DoubleDown"
        case .unknown:
            return "NONE"
        }
    }
}

private func translateSlope(slope: Double) -> SensorTrend {
    if slope > 3.5 {
        return .rapidlyRising
    } else if slope > 2 {
        return .fastRising
    } else if slope > 1 {
        return .rising
    } else if slope < -3.5 {
        return .rapidlyFalling
    } else if slope < -2 {
        return .fastFalling
    } else if slope < -1 {
        return .falling
    } else {
        return .constant
    }
}
