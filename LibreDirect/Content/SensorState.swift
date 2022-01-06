//
//  SensorState.swift
//  LibreDirect
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

    // MARK: Lifecycle

    init() {
        self = .unknown
    }
    
    init(_ state: UInt8) {
        switch state {
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

    init(_ fram: Data) {
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

    // MARK: Internal

    var description: String {
        self.rawValue
    }

    var localizedString: String {
        LocalizedString(self.rawValue)
    }
}
