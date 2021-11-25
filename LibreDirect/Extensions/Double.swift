//
//  Double.swift
//  LibreDirect
//


import Foundation

extension Double {
    var asMmolL: Decimal {
        let places = Double(1)
        let mmoll = self * GlucoseUnit.exchangeRate

        let divisor = pow(10.0, places)
        let result = (mmoll * divisor).rounded() / divisor

        return Decimal(result)
    }

    func asGlucose(unit: GlucoseUnit, withUnit: Bool = false) -> String {
        var glucose: String

        if unit == .mmolL {


            glucose = GlucoseFormatters.mmolLFormatter.string(from: self.asMmolL as NSNumber)!
        } else {
            glucose = String(self)
        }

        if withUnit {
            return "\(glucose) \(unit.description)"
        }

        return glucose
    }
}
