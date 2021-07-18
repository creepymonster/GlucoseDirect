//
//  LibreSensorState.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation

enum SensorState: String, Codable {
    case unknown = "Unknown"
    case expired = "Sensor is expired"
    case failure = "Sensor has failure"
    case notYetStarted = "Sensor not yet startet"
    case ready = "Sensor is ready"
    case shutdown = "Sensor is shut down"
    case starting = "Sensor in starting phase"

    init() {
        self = .unknown
    }

    init(fram: Data) {
        switch fram[4] {
        case 01:
            self = .notYetStarted
        case 02:
            self = .starting
        case 03:
            self = .ready
        case 04:
            self = .expired
        case 05:
            self = .shutdown
        case 06:
            self = .failure
        default:
            self = .unknown
        }
    }

    public var description: String {
        return "\(self.rawValue)"
    }
}
