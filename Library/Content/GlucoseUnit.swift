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

    var localizedString: String {
        self.rawValue
    }
}
