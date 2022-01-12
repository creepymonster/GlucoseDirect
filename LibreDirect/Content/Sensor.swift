//
//  Sensor.swift
//  LibreDirect
//

import Foundation

// MARK: - Sensor

struct Sensor: Codable {
    // MARK: Lifecycle

    init(uuid: Data, patchInfo: Data, fram: Data) {
        let family = SensorFamily(Int(patchInfo[2] >> 4))

        var age = 0
        if fram.count >= 318 {
            age = Int(fram[316]) + Int(fram[317]) << 8
        }

        var lifetime = 20_160
        if fram.count >= 328 {
            lifetime = Int(fram[326]) + Int(fram[327]) << 8
        }

        self.init(
            fram: fram,
            uuid: uuid,
            patchInfo: patchInfo,
            factoryCalibration: FactoryCalibration(fram: fram),
            family: family,
            type: SensorType(patchInfo),
            region: SensorRegion(patchInfo[3]),
            serial: sensorSerialNumber(uuid: uuid, sensorFamily: family),
            state: SensorState(fram[4]),
            age: age,
            lifetime: lifetime
        )
    }

    init(uuid: Data, patchInfo: Data, factoryCalibration: FactoryCalibration, family: SensorFamily, type: SensorType, region: SensorRegion, serial: String?, state: SensorState, age: Int, lifetime: Int, warmupTime: Int = 60) {
        pairingTimestamp = Date()
        fram = nil
        self.uuid = uuid
        self.patchInfo = patchInfo
        self.factoryCalibration = factoryCalibration
        self.family = family
        self.type = type
        self.region = region
        self.serial = serial
        self.state = state
        self.age = age
        self.lifetime = lifetime
        self.warmupTime = warmupTime
    }

    init(fram: Data, uuid: Data, patchInfo: Data, factoryCalibration: FactoryCalibration, family: SensorFamily, type: SensorType, region: SensorRegion, serial: String?, state: SensorState, age: Int, lifetime: Int, warmupTime: Int = 60) {
        pairingTimestamp = Date()
        self.fram = fram
        self.uuid = uuid
        self.patchInfo = patchInfo
        self.factoryCalibration = factoryCalibration
        self.family = family
        self.type = type
        self.region = region
        self.serial = serial
        self.state = state
        self.age = age
        self.lifetime = lifetime
        self.warmupTime = warmupTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        pairingTimestamp = try container.decode(Date.self, forKey: .pairingTimestamp)
        startTimestamp = try container.decodeIfPresent(Date.self, forKey: .startTimestamp) ?? nil
        fram = try container.decode(Data?.self, forKey: .fram)
        uuid = try container.decode(Data.self, forKey: .uuid)
        patchInfo = try container.decode(Data.self, forKey: .patchInfo)
        factoryCalibration = try container.decode(FactoryCalibration.self, forKey: .factoryCalibration)
        family = try container.decode(SensorFamily.self, forKey: .family)
        type = try container.decode(SensorType.self, forKey: .type)
        region = try container.decode(SensorRegion.self, forKey: .region)
        serial = try container.decode(String?.self, forKey: .serial)
        state = try container.decode(SensorState.self, forKey: .state)
        age = try container.decode(Int.self, forKey: .age)
        lifetime = try container.decode(Int.self, forKey: .lifetime)
        warmupTime = try container.decode(Int.self, forKey: .warmupTime)
    }

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case pairingTimestamp
        case startTimestamp
        case fram
        case uuid
        case patchInfo
        case factoryCalibration
        case family
        case type
        case region
        case serial
        case state
        case age
        case lifetime
        case warmupTime
    }

    var pairingTimestamp: Date
    var startTimestamp: Date?
    let fram: Data?
    let uuid: Data
    let patchInfo: Data
    let factoryCalibration: FactoryCalibration
    let family: SensorFamily
    let type: SensorType
    let region: SensorRegion
    let serial: String?
    var state: SensorState
    var age: Int
    var lifetime: Int
    let warmupTime: Int

    var remainingWarmupTime: Int? {
        if age < warmupTime {
            return warmupTime - age
        }

        return nil
    }

    var elapsedLifetime: Int? {
        if let remainingLifetime = remainingLifetime {
            return max(0, lifetime - remainingLifetime)
        }

        return nil
    }

    var remainingLifetime: Int? {
        max(0, lifetime - age)
    }

    var description: String {
        [
            "uuid: \(uuid.hex)",
            "patchInfo: \(patchInfo.hex)",
            "factoryCalibration: \(factoryCalibration.description)",
            "family: \(family.description)",
            "type: \(type.description)",
            "region: \(region.description)",
            "serial: \(serial ?? "Unknown")",
            "state: \(state.description)",
            "lifetime: \(lifetime.inTime)",
        ].joined(separator: ", ")
    }
}

private func sensorSerialNumber(uuid: Data, sensorFamily: SensorFamily) -> String? {
    let lookupTable = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "T", "U", "V", "W", "X", "Y", "Z"]

    guard uuid.count == 8 else {
        AppLog.info("Guard: uuid.count is not 8")
        return nil
    }

    let bytes = Array(uuid.reversed().suffix(6))
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

    return fiveBitsArray.reduce("\(sensorFamily.rawValue)") {
        $0 + lookupTable[Int(0x1f & $1)]
    }
}
