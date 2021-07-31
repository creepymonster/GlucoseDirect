//
//  UInt16Extensions.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 06.07.21.
//

import Foundation
import Combine

extension UInt16 {
    init(_ high: UInt8, _ low: UInt8) {
        self = UInt16(high) << 8 + UInt16(low)
    }

    init(_ data: Data) {
        self = UInt16(data[data.startIndex + 1]) << 8 + UInt16(data[data.startIndex])
    }
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
        return "\(self.inDays.description)d \(self.inHours.description)h \(self.inMinutes.description)m"
    }
    
    func map(inMin: Int, inMax: Int, outMin: Int, outMax: Int) -> Int {
        return (self - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
    }
}


/*long map(long x, long in_min, long in_max, long out_min, long out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}*/
