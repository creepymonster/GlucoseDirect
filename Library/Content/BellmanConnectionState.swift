//
//  BellmanConnectionState.swift
//  GlucoseDirect
//

import Foundation

// MARK: - BellmanConnectionState

enum BellmanConnectionState: String {
    case connected = "Connected"
    case connecting = "Connecting"
    case disconnected = "Disconnected"
    case unknown = "Unknown"

    // MARK: Lifecycle

    init() {
        self = .unknown
    }

    // MARK: Internal

    var description: String {
        rawValue
    }

    var localizedString: String {
        LocalizedString(rawValue)
    }
}
