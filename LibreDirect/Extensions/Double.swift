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

    func asGlucose(glucoseUnit: GlucoseUnit, withUnit: Bool = false) -> String {
        var glucose: String

        if glucoseUnit == .mmolL {
            glucose = GlucoseFormatters.mmolLFormatter.string(from: self.asMmolL as NSNumber)!
        } else {
            glucose = String(self)
        }

        if withUnit {
            return "\(glucose) \(glucoseUnit.localizedString)"
        }

        return glucose
    }
    
    func asMinuteChange(glucoseUnit: GlucoseUnit, withUnit: Bool = false) -> String {
        var formattedMinuteChange = ""

        if glucoseUnit == .mgdL {
            formattedMinuteChange = GlucoseFormatters.minuteChangeFormatter.string(from: self as NSNumber)!
        } else {
            formattedMinuteChange = GlucoseFormatters.minuteChangeFormatter.string(from: self.asMmolL as NSNumber)!
        }

        if withUnit {
            return String(format: LocalizedString("%1$@ %2$@/min.", comment: ""), formattedMinuteChange, glucoseUnit.localizedString)
        }
        
        return String(format: LocalizedString("%1$@/min.", comment: ""), formattedMinuteChange)
    }
}
