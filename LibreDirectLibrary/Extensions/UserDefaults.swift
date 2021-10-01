//
//  UserDefaults.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 28.07.21. 
//

import Foundation

public extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: AppConfig.AppGroupName)!

    func setArray<Element>(_ array: [Element], forKey key: String) where Element: Encodable {
        let data = try? JSONEncoder().encode(array)
        set(data, forKey: key)
    }

    func getArray<Element>(forKey key: String) -> [Element]? where Element: Decodable {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([Element].self, from: data)
    }

    func setObject<Element>(_ obj: Element, forKey key: String) where Element: Encodable {
        let data = try? JSONEncoder().encode(obj)
        set(data, forKey: key)
    }

    func getObject<Element>(forKey key: String) -> Element? where Element: Decodable {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Element.self, from: data)
    }
}

fileprivate enum Keys: String {
    case alarmHigh = "libre-direct.settings.alarm-high"
    case alarmLow = "libre-direct.settings.alarm-low"
    case freeAPSLatestReadings = "latestReadings"
    case glucoseValues = "libre-direct.settings.glucose-values"
    case lastGlucose = "libre-direct.settings.last-glucose"
    case nightscoutUpload = "libre-direct.nightscout-upload-enabled"
    case nightscoutApiSecret = "libre-direct.settings.nightscout-api-secret"
    case nightscoutHost = "libre-direct.settings.nightscout-host"
    case glucoseUnit = "libre-direct.settings.glucose-unit"
    case sensor = "libre-direct.settings.sensor"
}

public extension UserDefaults {
    var alarmHigh: Int? {
        get {
            if UserDefaults.standard.object(forKey: Keys.alarmHigh.rawValue) != nil {
                return integer(forKey: Keys.alarmHigh.rawValue)
            }

            return nil
        }
        set {
            set(newValue, forKey: Keys.alarmHigh.rawValue)
        }
    }

    var alarmLow: Int? {
        get {
            if UserDefaults.standard.object(forKey: Keys.alarmLow.rawValue) != nil {
                return integer(forKey: Keys.alarmLow.rawValue)
            }

            return nil
        }
        set {
            set(newValue, forKey: Keys.alarmLow.rawValue)
        }
    }

    var freeAPSLatestReadings: Data? {
        get {
            return data(forKey: Keys.freeAPSLatestReadings.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.freeAPSLatestReadings.rawValue)
            } else {
                removeObject(forKey: Keys.freeAPSLatestReadings.rawValue)
            }
        }
    }

    var glucoseUnit: GlucoseUnit {
        get {
            if let glucoseUnitValue = object(forKey: Keys.glucoseUnit.rawValue) as? String {
                return GlucoseUnit(rawValue: glucoseUnitValue)!
            }

            return .mgdL
        }
        set {
            set(newValue.rawValue, forKey: Keys.glucoseUnit.rawValue)
        }
    }

    var glucoseValues: [SensorGlucose] {
        get {
            return getArray(forKey: Keys.glucoseValues.rawValue) ?? []
        }
        set {
            setArray(newValue, forKey: Keys.glucoseValues.rawValue)
        }
    }

    var lastGlucose: SensorGlucose? {
        get {
            return getObject(forKey: Keys.lastGlucose.rawValue)
        }
        set {
            setObject(newValue, forKey: Keys.lastGlucose.rawValue)
        }
    }

    var nightscoutUpload: Bool {
        get {
            return bool(forKey: Keys.nightscoutUpload.rawValue)
        }
        set {
            set(newValue, forKey: Keys.nightscoutUpload.rawValue)
        }
    }

    var nightscoutApiSecret: String {
        get {
            return string(forKey: Keys.nightscoutApiSecret.rawValue) ?? ""
        }
        set {
            if newValue.isEmpty {
                removeObject(forKey: Keys.nightscoutApiSecret.rawValue)
            } else {
                set(newValue, forKey: Keys.nightscoutApiSecret.rawValue)
            }
        }
    }

    var nightscoutHost: String {
        get {
            return string(forKey: Keys.nightscoutHost.rawValue) ?? ""
        }
        set {
            if newValue.isEmpty {
                removeObject(forKey: Keys.nightscoutHost.rawValue)
            } else {
                set(newValue, forKey: Keys.nightscoutHost.rawValue)
            }
        }
    }

    var sensor: Sensor? {
        get {
            return getObject(forKey: Keys.sensor.rawValue)
        }
        set {
            if let newValue = newValue {
                setObject(newValue, forKey: Keys.sensor.rawValue)
            } else {
                removeObject(forKey: Keys.sensor.rawValue)
            }
        }
    }
}
