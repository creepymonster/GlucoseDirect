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

    init(averageGlucose: Double, currentGlucose: Double) {
        let slope = averageGlucose - currentGlucose
        self = translateSlope(slope: slope)
    }

    init(secondLast: SensorGlucose, last: SensorGlucose) {
        let slope = calculateSlope(secondLast: secondLast, last: last)
        self = translateSlope(slope: slope)
    }

    init(slope: Double) {
        self = translateSlope(slope: slope)
    }

    public var description: String {
        return "\(self.rawValue)"
    }
}

fileprivate func calculateDiffInMinutes(secondLast: Date, last: Date) -> Double {
    let diff = last.timeIntervalSince(secondLast)
    return diff / 60
}

fileprivate func calculateSlope(secondLast: SensorGlucose, last: SensorGlucose) -> Double {
    if secondLast.timeStamp == last.timeStamp {
        return 0.0
    }

    let glucoseDiff = Double(last.glucose) - Double(secondLast.glucose)
    let minutesDiff = calculateDiffInMinutes(secondLast: secondLast.timeStamp, last: last.timeStamp)

    return glucoseDiff / minutesDiff
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
