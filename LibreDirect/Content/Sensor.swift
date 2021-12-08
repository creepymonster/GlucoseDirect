//
//  Sensor.swift
//  LibreDirect
//

import Foundation

// MARK: - Sensor

class Sensor: Codable {
    // MARK: Lifecycle

    convenience init(uuid: Data, patchInfo: Data, fram: Data) {
        let family = SensorFamily(Int(patchInfo[2] >> 4))

        self.init(
            fram: fram,
            uuid: uuid,
            patchInfo: patchInfo,
            factoryCalibration: FactoryCalibration(fram: fram),
            customCalibration: [],
            family: family,
            type: SensorType(patchInfo),
            region: SensorRegion(patchInfo[3]),
            serial: sensorSerialNumber(uuid: uuid, sensorFamily: family),
            state: SensorState(fram[4]),
            age: Int(fram[316]) + Int(fram[317]) << 8,
            lifetime: Int(fram[326]) + Int(fram[327]) << 8
        )
    }

    init(uuid: Data, patchInfo: Data, factoryCalibration: FactoryCalibration, customCalibration: [CustomCalibration], family: SensorFamily, type: SensorType, region: SensorRegion, serial: String?, state: SensorState, age: Int, lifetime: Int, warmupTime: Int = 60) {
        self.pairingTimestamp = Date()
        self.fram = nil
        self.uuid = uuid
        self.patchInfo = patchInfo
        self.factoryCalibration = factoryCalibration
        self.customCalibration = customCalibration
        self.family = family
        self.type = type
        self.region = region
        self.serial = serial
        self.state = state
        self.age = age
        self.lifetime = lifetime
        self.warmupTime = warmupTime
    }

    init(fram: Data, uuid: Data, patchInfo: Data, factoryCalibration: FactoryCalibration, customCalibration: [CustomCalibration], family: SensorFamily, type: SensorType, region: SensorRegion, serial: String?, state: SensorState, age: Int, lifetime: Int, warmupTime: Int = 60) {
        self.pairingTimestamp = Date()
        self.fram = fram
        self.uuid = uuid
        self.patchInfo = patchInfo
        self.factoryCalibration = factoryCalibration
        self.customCalibration = customCalibration
        self.family = family
        self.type = type
        self.region = region
        self.serial = serial
        self.state = state
        self.age = age
        self.lifetime = lifetime
        self.warmupTime = warmupTime
    }

    // MARK: Internal

    var pairingTimestamp: Date
    let fram: Data?
    let uuid: Data
    let patchInfo: Data
    let factoryCalibration: FactoryCalibration
    var customCalibration: [CustomCalibration]
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
