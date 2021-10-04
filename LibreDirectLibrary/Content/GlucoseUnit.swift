//
//  GlucoseUnit.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 02.08.21.
//

import Foundation

public enum GlucoseUnit: String, Codable {
    case mgdL = "mg/dL"
    case mmolL = "mmol/L"

    static let exchangeRate: Double = 0.0555
    
    public var description: String {
        switch self {
        case .mgdL:
            return "mg/dL"
            
        case .mmolL:
            return "mmol/L"
        }
    }
}
