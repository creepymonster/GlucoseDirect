//
//  Int.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation
import Combine
import SwiftUI

public extension UInt16 {
    init(_ high: UInt8, _ low: UInt8) {
        self = UInt16(high) << 8 + UInt16(low)
    }

    init(_ data: Data) {
        self = UInt16(data[data.startIndex + 1]) << 8 + UInt16(data[data.startIndex])
    }
}

public extension Int {
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
        return String(format: LocalizedString("%1$@d %2$@h %3$@min", comment: ""), self.inDays.description, self.inHours.description, self.inMinutes.description)
    }

    var asMmolL: Decimal {
        return Decimal(self) * GlucoseUnit.exchangeRate
    }

    var asMgdL: Int {
        return self
    }

    func asGlucose(unit: GlucoseUnit, withUnit: Bool = false) -> String {
        var glucose: String
        
        if unit == .mmolL {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1

            glucose = formatter.string(from: self.asMmolL as NSNumber)!
        } else {
            glucose = String(self.asMgdL)
        }

        if withUnit {
            return "\(glucose) \(unit.description)"
        }
        
        return glucose
    }

    func map(inMin: Int, inMax: Int, outMin: Int, outMax: Int) -> Int {
        return (self - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
    }
}
