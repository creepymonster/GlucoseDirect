//
//  SensorCalibration.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation

struct SensorCalibration: Codable {
    var i1: Int
    var i2: Int
    var i3: Double
    var i4: Double
    var i5: Double
    var i6: Double

    init(i1: Int, i2: Int, i3: Double, i4: Double, i5: Double, i6: Double) {
        self.i1 = i1
        self.i2 = i2
        self.i3 = i3
        self.i4 = i4
        self.i5 = i5
        self.i6 = i6
    }

    init(fram: Data) {
        func readBits(_ buffer: Data, _ byteOffset: Int, _ bitOffset: Int, _ bitCount: Int) -> Int {
            guard bitCount != 0 else {
                return 0
            }
            var res = 0
            for i in 0 ..< bitCount {
                let totalBitOffset = byteOffset * 8 + bitOffset + i
                let byte = Int(floor(Float(totalBitOffset) / 8))
                let bit = totalBitOffset % 8
                if totalBitOffset >= 0 && ((Int(buffer[byte]) >> bit) & 0x1) == 1 {
                    res = res | (1 << i)
                }
            }
            return res
        }

        self.i1 = readBits(fram, 2, 0, 3)
        self.i2 = readBits(fram, 2, 3, 0xa)
        self.i3 = Double(readBits(fram, 0x150, 0, 8))

        if readBits(fram, 0x150, 0x21, 1) != 0 {
            self.i3 = -i3
        }

        self.i4 = Double(readBits(fram, 0x150, 8, 0xe))
        self.i5 = Double(readBits(fram, 0x150, 0x28, 0xc) << 2)
        self.i6 = Double(readBits(fram, 0x150, 0x34, 0xc) << 2)
    }

    public var description: String {
        return [
            "\(i1)",
            "\(i2)",
            "\(i3)",
            "\(i4)",
            "\(i5)",
            "\(i6)"
        ].joined(separator: ", ")
    }
}
