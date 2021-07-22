//
//  SensorTrend.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation

enum SensorTrend: String, Codable {
    case rapidlyRising = "⇈"
    case fastRising = "↑"
    case rising = "↗︎"
    case constant = "→"
    case falling = "↘︎"
    case fastFalling = "↓"
    case rapidlyFalling = "⇊"
    case unknown = ""

    init() {
        self = .unknown
    }

    init(slope: Double) {
        self = translateSlope(slope: slope)
    }

    public var description: String {
        return "\(self.rawValue)"
    }
}

fileprivate func translateSlope(slope: Double) -> SensorTrend {
    if slope > 3.5 {
        return .rapidlyRising
    } else if slope > 2 {
        return .fastRising
    } else if slope > 1 {
        return .rising
    } else if slope > -1 {
        return .constant
    } else if slope > -2 {
        return .falling
    } else if slope > -3.5 {
        return .fastFalling
    } else {
        return .rapidlyFalling
    }
}
