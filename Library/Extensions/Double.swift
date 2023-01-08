//
//  Double.swift
//  GlucoseDirect
//

import Foundation

extension Double {
    var asMmolL: Double {
        return self * GlucoseUnit.exchangeRate
    }

    var asMgdL: Double {
        return self
    }

    func asPercent(_ increment: Double = 1) -> String {
        return self.formatted(.percent.scale(1.0).rounded(increment: increment))
    }
    
    func map(from: ClosedRange<Double>, to: ClosedRange<Double>) -> Double {
        let result = ((self - from.lowerBound) / (from.upperBound - from.lowerBound)) * (to.upperBound - to.lowerBound) + to.lowerBound
        return result
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
    
    func asInsulin() -> String {
        return GlucoseFormatters.insulinFormatter.string(from: self as NSNumber)!
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

    func toInteger() -> Int? {
        if self >= Double(Int.min), self < Double(Int.max) {
            return Int(self.rounded())
        } else {
            return nil
        }
    }
}
