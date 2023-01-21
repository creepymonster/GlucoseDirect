//
//  Double.swift
//  GlucoseDirect
//

import Foundation

extension Double {
    func map(from: ClosedRange<Double>, to: ClosedRange<Double>) -> Double {
        let result = ((self - from.lowerBound) / (from.upperBound - from.lowerBound)) * (to.upperBound - to.lowerBound) + to.lowerBound
        return result
    }

    func asInsulin() -> String {
        return GlucoseFormatters.insulinFormatter.string(from: self as NSNumber)!
    }

    func asShortMinuteChange(glucoseUnit: GlucoseUnit, withUnit: Bool = false) -> String {
        var formattedMinuteChange = ""

        if glucoseUnit == .mgdL {
            formattedMinuteChange = GlucoseFormatters.minuteChangeFormatter.string(from: self as NSNumber)!
        } else {
            formattedMinuteChange = GlucoseFormatters.minuteChangeFormatter.string(from: self.toMmolL() as NSNumber)!
        }

        if withUnit {
            return String(format: LocalizedString("%1$@ %2$@"), formattedMinuteChange, glucoseUnit.localizedDescription)
        }

        return String(format: LocalizedString("%1$@"), formattedMinuteChange)
    }

    func asMinuteChange(glucoseUnit: GlucoseUnit, withUnit: Bool = false) -> String {
        let formattedMinuteChange = self.asShortMinuteChange(glucoseUnit: glucoseUnit, withUnit: withUnit)

        return String(format: LocalizedString("%1$@/min."), formattedMinuteChange)
    }

    func asPercent(_ increment: Double = 1) -> String {
        return self.formatted(.percent.scale(1.0).rounded(increment: increment))
    }

    func toMmolL() -> Double {
        return self * GlucoseUnit.exchangeRate
    }

    func toMgdl() -> Int? {
        if let value = (self / GlucoseUnit.exchangeRate).toInteger() {
            return value
        }

        return nil
    }

    func toInteger() -> Int? {
        if self >= Double(Int.min), self < Double(Int.max) {
            return Int(self.rounded())
        } else {
            return nil
        }
    }
}
