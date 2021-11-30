//
//  Transmitter.swift
//  LibreDirect
//

import Foundation

struct Transmitter: CustomStringConvertible, Codable {
    // MARK: Lifecycle

    init(name: String, battery: Int, firmware: Double? = nil, hardware: Double? = nil) {
        self.battery = battery
        self.name = name
        self.firmware = firmware
        self.hardware = hardware
    }

    // MARK: Internal

    let name: String
    var battery: Int
    let firmware: Double?
    let hardware: Double?

    var description: String {
        [
            "battery: \(battery.description)",
            "name: \(name.description)",
            "firmware: \(firmware?.description ?? "-")",
            "hardware: \(hardware?.description ?? "-")"
        ].joined(separator: ", ")
    }
}
