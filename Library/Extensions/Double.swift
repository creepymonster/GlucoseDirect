//
//  Double.swift
//  GlucoseDirect
//

import Foundation

extension Double {
    var asMmolL: Decimal {
        return Decimal(self * GlucoseUnit.exchangeRate)
    }

    var asMgdL: Decimal {
        return Decimal(self)
    }

    func asPercent() -> String {
        return "\(GlucoseFormatters.percentFormatter.string(from: self as NSNumber)!)%"
    }

    func asInteger() -> String {
        GlucoseFormatters.integerFormatter.string(from: self as NSNumber)!
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
            if precise {
                glucose = GlucoseFormatters.preciseMgdLFormatter.string(from: self as NSNumber)!
            } else {
                glucose = GlucoseFormatters.mgdLFormatter.string(from: self as NSNumber)!
            }
        }

        if withUnit {
            return "\(glucose) \(glucoseUnit.localizedDescription)"
        }

        return glucose
    }
    
    func asShortMinuteChange(glucoseUnit: GlucoseUnit, withUnit: Bool = false) -> String {
        var formattedMinuteChange = ""

        if glucoseUnit == .mgdL {
            formattedMinuteChange = GlucoseFormatters.minuteChangeFormatter.string(from: self as NSNumber)!
        } else {
            formattedMinuteChange = GlucoseFormatters.minuteChangeFormatter.string(from: self.asMmolL as NSNumber)!
        }

        if withUnit {
            return String(format: LocalizedString("%1$@ %2$@"), formattedMinuteChange, glucoseUnit.localizedDescription)
        }

        return String(format: LocalizedString("%1$@"), formattedMinuteChange)
    }

    func asMinuteChange(glucoseUnit: GlucoseUnit, withUnit: Bool = false) -> String {
        let formattedMinuteChange = asShortMinuteChange(glucoseUnit: glucoseUnit, withUnit: withUnit)

        return String(format: LocalizedString("%1$@/min."), formattedMinuteChange)
    }

    func toInt() -> Int? {
        if self >= Double(Int.min), self < Double(Int.max) {
            return Int(self)
        } else {
            return nil
        }
    }
}
