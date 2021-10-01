//
//  LibreConnectionState.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation

public enum SensorConnectionState: String {
    case connected = "Connected"
    case connecting = "Connecting"
    case disconnected = "Disconnected"
    case powerOff = "Power Off"
    case scanning = "Scanning"
    case unknown = "Unknown"

    public init() {
        self = .unknown
    }

    public var description: String {
        return self.rawValue
    }
}
