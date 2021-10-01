//
//  SensorFamily.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation

public enum SensorFamily: Int, Codable {
    case unknown = -1
    case libre1 = 0
    case librePro = 1
    case libre2 = 3
    case libreSense = 7

    public init() {
        self = .unknown
    }

    public init(patchInfo: Data) {
        let family = Int(patchInfo[2] >> 4)

        switch family {
        case 0:
            self = .libre1
        case 1:
            self = .librePro
        case 3:
            self = .libre2
        case 7:
            self = .libreSense
        default:
            self = .unknown
        }
    }

    public var description: String {
        switch self {
        case .libre1:
            return "Libre 1"
        case .librePro:
            return "Libre Pro/H"
        case .libre2:
            return "Libre 2"
        case .libreSense:
            return "Libre Sense"
        default:
            return "Unknown"
        }
    }
}
