//
//  GlucoseUnit.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 02.08.21.
//

import Foundation

enum GlucoseUnit: String, Codable {
    case mgdL = "mg/dL"
    case mmolL = "mmol/L"

    static let exchangeRate: Decimal = 0.0555
    
    var description: String {
        switch self {
        case .mgdL:
            return "mg/dL"
            
        case .mmolL:
            return "mmol/L"
        }
    }
}
