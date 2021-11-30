//
//  Sensor.swift
//  LibreDirect
//

import Foundation

// MARK: - Sensor

struct Sensor: Codable {
    // MARK: Lifecycle

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
