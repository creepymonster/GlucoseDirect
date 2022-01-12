//
//  LibreConnectionState.swift
//  LibreDirect
//

import Foundation

enum SensorConnectionState: String {
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
        self.rawValue
    }

    var localizedString: String {
        LocalizedString(self.rawValue)
    }
}
