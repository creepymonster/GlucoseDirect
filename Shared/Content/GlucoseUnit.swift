//
//  GlucoseUnit.swift
//  GlucoseDirect
//

import Foundation

enum GlucoseUnit: String, Codable, Hashable {
    case mgdL = "mg/dL"
    case mmolL = "mmol/L"

    // MARK: Internal

    static let exchangeRate: Double = 0.0555

    var localizedDescription: String {
        self.rawValue
    }

    var shortLocalizedDescription: String {
        switch self {
        case .mgdL:
            return "mg"
        case .mmolL:
            return "mmol"
        }
    }
}
