//
//  SensorTrend.swift
//  LibreDirect
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
    case unknown = ""

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
