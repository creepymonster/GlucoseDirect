//
//  SensorType.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation

enum SensorType: String, Codable {
    case unknown = "Unknown"
    case libre1 = "Libre 1"
    case libre2EU = "Libre 2 EU"
    case libre2CA = "Libre 2 CA"
    case libre2US = "Libre 2 US"
    case libre3 = "Libre 3"
    case libreProH = "Libre Pro/H"
    case libreSense = "Libre Sense"
    case libreUS14day = "Libre US 14d"

    init() {
        self = .unknown
    }

    init(patchInfo: Data) {
        switch patchInfo[0] {
        case 0xDF:
            self = .libre1
        case 0xA2:
            self = .libre1
        case 0xE5:
            self = .libreUS14day
        case 0x70:
            self = .libreProH
        case 0x9D:
            self = .libre2EU
        case 0x76:
            self = patchInfo[3] == 0x02 ? .libre2US : patchInfo[3] == 0x04 ? .libre2CA : patchInfo[2] >> 4 == 7 ? .libreSense : .unknown
        default:
            if patchInfo.count > 6 { // Libre 3's NFC A1 command ruturns 35 or 28 bytes
                self = .libre3
            } else {
                self = .unknown
            }
        }
    }

    init(_ value: String) {
        if value.count > 1 {
            let firstTwoChars = value.prefix(2) // patchInfo[0..<2].uppercased()

            switch firstTwoChars {
            case "DF":
                self = .libre1
            case "A2":
                self = .libre1
            case "9D":
                self = .libre2EU
            case "E5":
                self = .libreUS14day
            case "70":
                self = .libreProH
            default:
                self = .unknown
            }
        } else {
            self = .unknown
        }
    }

    var description: String {
        return self.rawValue
    }
}
