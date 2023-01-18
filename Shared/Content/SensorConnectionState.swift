//
//  LibreConnectionState.swift
//  GlucoseDirect
//

import Foundation

enum SensorConnectionState: String, Codable {
    case pairing = "Pairing"
    case connected = "Connected"
    case connecting = "Connecting"
    case disconnected = "Disconnected"
    case powerOff = "Power off"
    case scanning = "Scanning"
    case unknown = "Unknown"

    // MARK: Lifecycle

    init() {
        self = .unknown
    }

    // MARK: Internal

    var description: String {
        rawValue
    }

    var localizedDescription: String {
        LocalizedString(rawValue)
    }
}
