//
//  Double.swift
//  LibreDirect
//

import Foundation

extension Double {
    var asMmolL: Decimal {
        return Decimal(self * GlucoseUnit.exchangeRate)
    }

    func asGlucose(glucoseUnit: GlucoseUnit, withUnit: Bool = false, precise: Bool = false) -> String {
        var glucose: String

        if glucoseUnit == .mmolL {
            if precise {
                glucose = GlucoseFormatters.preciseMmolLFormatter.string(from: self.asMmolL as NSNumber)!
            } else {
                glucose = GlucoseFormatters.mmolLFormatter.string(from: self.asMmolL as NSNumber)!
            }
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
