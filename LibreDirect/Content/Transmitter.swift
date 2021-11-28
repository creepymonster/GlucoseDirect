//
//  Transmitter.swift
//  LibreDirect
//

import Foundation

struct Transmitter: CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle

    init(id: String, battery: Int, name: String?, manufacturer: String? = nil, firmware: String? = nil, hardware: String? = nil) {
        self.id = id
        self.battery = battery
        self.name = name
        self.manufacturer = manufacturer
        self.firmware = firmware
        self.hardware = hardware
    }

    // MARK: Internal

    let id: String
    var battery: Int
    let name: String?
    let manufacturer: String?
    let firmware: String?
    let hardware: String?

    var description: String {
        [
            "id: \(id)",
            "battery: \(battery.description)",
            "name: \(name?.description ?? "-")",
            "manufacturer: \(manufacturer?.description ?? "-")",
            "firmware: \(firmware?.description ?? "-")",
            "hardware: \(hardware?.description ?? "-")"
        ].joined(separator: ", ")
    }
}
