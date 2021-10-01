//
//  Sensor.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation

public struct Sensor: Codable {
    public let uuid: Data
    public let patchInfo: Data
    public let calibration: SensorCalibration
    public let family: SensorFamily
    public let type: SensorType
    public let region: SensorRegion
    public let serial: String?
    public var state: SensorState
    public var age: Int
    public var lifetime: Int

    public var elapsedLifetime: Int? {
        get {
            if let remainingLifetime = remainingLifetime {
                return max(0, lifetime - remainingLifetime)
            }

            return nil
        }
    }

    public var remainingLifetime: Int? {
        get {
            return max(0, lifetime - age)
        }
    }

    public init(uuid: Data, patchInfo: Data, fram: Data) {
        self.uuid = uuid
        self.patchInfo = patchInfo
        self.calibration = SensorCalibration(fram: fram)
        self.family = SensorFamily(patchInfo: patchInfo)
        self.type = SensorType(patchInfo: patchInfo)
        self.region = SensorRegion(patchInfo: patchInfo)
        self.serial = sensorSerialNumber(sensorUID: self.uuid, sensorFamily: self.family)
        self.state = SensorState(fram: fram)
        self.age = Int(fram[317]) << 8 + Int(fram[316])
        self.lifetime = Int(fram[327]) << 8 + Int(fram[326])
    }

    public var description: String {
        return [
            "uuid: (\(uuid.hex))",
            "patchInfo: (\(patchInfo.hex))",
            "calibration: (\(calibration.description))",
            "family: \(family.description)",
            "type: \(type.description)",
            "region: \(region.description)",
            "serial: \(serial ?? "Unknown")",
            "state: \(state.description)",
            "lifetime: \(lifetime.inTime)",
        ].joined(separator: ", ")
    }
}

fileprivate func sensorSerialNumber(sensorUID: Data, sensorFamily: SensorFamily) -> String? {
    let lookupTable = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "T", "U", "V", "W", "X", "Y", "Z"]

    guard sensorUID.count == 8 else {
        return nil
    }

    let bytes = Array(sensorUID.reversed().suffix(6))
    var fiveBitsArray = [UInt8]()
    fiveBitsArray.append(bytes[0] >> 3)
    fiveBitsArray.append(bytes[0] << 2 + bytes[1] >> 6)

    fiveBitsArray.append(bytes[1] >> 1)
    fiveBitsArray.append(bytes[1] << 4 + bytes[2] >> 4)

    fiveBitsArray.append(bytes[2] << 1 + bytes[3] >> 7)

    fiveBitsArray.append(bytes[3] >> 2)
    fiveBitsArray.append(bytes[3] << 3 + bytes[4] >> 5)

    fiveBitsArray.append(bytes[4])

    fiveBitsArray.append(bytes[5] >> 3)
    fiveBitsArray.append(bytes[5] << 2)

    return fiveBitsArray.reduce("\(sensorFamily.rawValue)", {
        $0 + lookupTable[Int(0x1F & $1)]
    })
}
