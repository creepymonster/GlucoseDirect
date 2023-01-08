//
//  Int.swift
//  GlucoseDirect
//

import Combine
import Foundation
import SwiftUI

// MARK: - GlucoseFormatters

struct GlucoseFormatters {
    static var mgdLFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0

        return formatter
    }()

    static var preciseMgdLFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        return formatter
    }()

    static var mmolLFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1

        return formatter
    }()

    static var preciseMmolLFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2

        return formatter
    }()

    static var minuteChangeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.positivePrefix = "+"
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1

        return formatter
    }()
}

extension Int {
    var inDays: Int {
        let minutes = Double(self)

        return Int(minutes / 24 / 60)
    }

    var inHours: Int {
        let minutes = Double(self)

        return Int((minutes / 60).truncatingRemainder(dividingBy: 24))
    }

    var inMinutes: Int {
        let minutes = Double(self)

        return Int(minutes.truncatingRemainder(dividingBy: 60))
    }

    var inTime: String {
        if inDays > 0 {
            return String(format: LocalizedString("%1$@d %2$@h %3$@min"), inDays.description, inHours.description, inMinutes.description)
        }

        if inHours > 0 {
            return String(format: LocalizedString("%1$@h %2$@min"), inHours.description, inMinutes.description)
        }

        return String(format: LocalizedString("%1$@min"), inMinutes.description)
    }

    var inTimeSummary: String {
        let days = inDays
        let hours = (inDays > 0 || inHours > 0) && inMinutes > 0
            ? inHours + 1
            : inHours
        let minutes = inMinutes

        if days > 1 {
            return String(format: LocalizedString("%1$@ days"), days.description)
        } else if days > 0 {
            return String(format: LocalizedString("%1$@ day"), days.description)
        } else if hours > 1 {
            return String(format: LocalizedString("%1$@ hours"), hours.description)
        } else if hours > 0 {
            return String(format: LocalizedString("%1$@ hour"), hours.description)
        }

        return String(format: LocalizedString("%1$@ minutes"), minutes.description)
    }

    var asMmolL: Double {
        return Double(self).asMmolL
    }

    var asMgdL: Double {
        return Double(self)
    }

    func map(from: ClosedRange<Int>, to: ClosedRange<Int>) -> Int {
        let result = ((self - from.lowerBound) / (from.upperBound - from.lowerBound)) * (to.upperBound - to.lowerBound) + to.lowerBound
        return result
    }

    func pluralize(singular: String, plural: String) -> String {
        if self == 1 {
            return singular
        }

        return plural
    }

    func pluralizeLocalization(singular: String, plural: String) -> String {
        return pluralize(singular: String(format: LocalizedString(singular), description), plural: String(format: LocalizedString(plural), description))
    }

    func asPercent() -> String {
        return formatted(.percent.scale(1.0))
    }

    func toPercent(of: Int) -> Double {
        return 100.0 / Double(of) * Double(self)
    }

    func isAlmost(_ lower: Int, _ upper: Int) -> Bool {
        if self >= (lower - 1), self <= (lower + 1) {
            return true
        }

        if self >= (upper - 1), self <= (upper + 1) {
            return true
        }

        return false
    }

    func asGlucose(glucoseUnit: GlucoseUnit, withUnit: Bool = false, precise: Bool = false) -> String {
        var glucose: String

        if glucoseUnit == .mmolL {
            if precise {
                glucose = GlucoseFormatters.preciseMmolLFormatter.string(from: asMmolL as NSNumber)!
            } else {
                glucose = GlucoseFormatters.mmolLFormatter.string(from: asMmolL as NSNumber)!
            }
        } else {
            glucose = String(self)
        }

        if withUnit {
            return "\(glucose) \(glucoseUnit.localizedDescription)"
        }

        return glucose
    }
}

extension UInt16 {
    init(_ high: UInt8, _ low: UInt8) {
        self = UInt16(high) << 8 + UInt16(low)
    }

    init(_ data: Data) {
        self = UInt16(data[data.startIndex + 1]) << 8 + UInt16(data[data.startIndex])
    }
}

extension UInt64 {
    func asFileSize() -> String {
        var convertedValue = Double(self)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]

        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }
}
