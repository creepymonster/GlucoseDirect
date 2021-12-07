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

    var localizedString: String {
        NSLocalizedString(self.rawValue, comment: "")
    }
}
