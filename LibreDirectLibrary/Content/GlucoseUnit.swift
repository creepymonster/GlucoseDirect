//
//  GlucoseUnit.swift
//  LibreDirect
//

import Foundation

enum GlucoseUnit: String, Codable {
    case mgdL = "mg/dL"
    case mmolL = "mmol/L"

    // MARK: Internal

    static let exchangeRate: Double = 0.0555

    var description: String {
        switch self {
        case .mgdL:
            return "mg/dL"

        case .mmolL:
            return "mmol/L"
        }
    }

    var localizedString: String {
        NSLocalizedString(self.rawValue, comment: "")
    }
}
