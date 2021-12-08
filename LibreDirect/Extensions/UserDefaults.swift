//
//  UserDefaults.swift
//  LibreDirect
//

import Foundation

// MARK: - Keys

private enum Keys: String {
    case alarmHigh = "libre-direct.settings.alarm-high"
    case alarmLow = "libre-direct.settings.alarm-low"
    case calendarExport = "libre-direct.settings.calendar-export"
    case chartShowLines = "libre-direct.settings.chart-show-lines"
    case connectionAlarm = "libre-direct.settings.connection-alarm"
    case expiringAlarm = "libre-direct.settings.expiring-alarm"
    case latestReadings = "latestReadings"
    case glucoseAlarm = "libre-direct.settings.glucose-alarm"
    case glucoseBadge = "libre-direct.settings.glucose-badge"
    case glucoseUnit = "libre-direct.settings.glucose-unit"
    case glucoseValues = "libre-direct.settings.glucose-values"
    case nightscoutApiSecret = "libre-direct.settings.nightscout-api-secret"
    case nightscoutHost = "libre-direct.settings.nightscout-host"
    case nightscoutUpload = "libre-direct.settings.nightscout-upload-enabled"
    case selectedCalendarTarget = "libre-direct.settings.selected-calendar-target"
    case selectedConnectionId = "libre-direct.settings.selected-connection-id"
    case selectedView = "libre-direct.settings.selected-view"
    case sensor = "libre-direct.settings.sensor"
    case transmitter = "libre-direct.settings.transmitter"
}

extension UserDefaults {
    var alarmHigh: Int? {
        get {
            if object(forKey: Keys.alarmHigh.rawValue) != nil {
                return integer(forKey: Keys.alarmHigh.rawValue)
            }

            return nil
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.alarmHigh.rawValue)
            } else {
                removeObject(forKey: Keys.alarmHigh.rawValue)
            }
        }
    }

    var alarmLow: Int? {
        get {
            if object(forKey: Keys.alarmLow.rawValue) != nil {
                return integer(forKey: Keys.alarmLow.rawValue)
            }

            return nil
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.alarmLow.rawValue)
            } else {
                removeObject(forKey: Keys.alarmLow.rawValue)
            }
        }
    }

    var calendarExport: Bool {
        get {
            if object(forKey: Keys.calendarExport.rawValue) != nil {
                return bool(forKey: Keys.calendarExport.rawValue)
            }

            return false
        }
        set {
            set(newValue, forKey: Keys.calendarExport.rawValue)
        }
    }

    var chartShowLines: Bool {
        get {
            if object(forKey: Keys.chartShowLines.rawValue) != nil {
                return bool(forKey: Keys.chartShowLines.rawValue)
            }

            return false
        }
        set {
            set(newValue, forKey: Keys.chartShowLines.rawValue)
        }
    }
    
    var connectionAlarm: Bool {
        get {
            if object(forKey: Keys.connectionAlarm.rawValue) != nil {
                return bool(forKey: Keys.connectionAlarm.rawValue)
            }

            return true
        }
        set {
            set(newValue, forKey: Keys.connectionAlarm.rawValue)
        }
    }

    var expiringAlarm: Bool {
        get {
            if object(forKey: Keys.expiringAlarm.rawValue) != nil {
                return bool(forKey: Keys.expiringAlarm.rawValue)
            }

            return true
        }
        set {
            set(newValue, forKey: Keys.expiringAlarm.rawValue)
        }
    }

    var glucoseAlarm: Bool {
        get {
            if object(forKey: Keys.glucoseAlarm.rawValue) != nil {
                return bool(forKey: Keys.glucoseAlarm.rawValue)
            }

            return true
        }
        set {
            set(newValue, forKey: Keys.glucoseAlarm.rawValue)
        }
    }

    var glucoseBadge: Bool {
        get {
            if object(forKey: Keys.glucoseBadge.rawValue) != nil {
                return bool(forKey: Keys.glucoseBadge.rawValue)
            }

            return true
        }
        set {
            set(newValue, forKey: Keys.glucoseBadge.rawValue)
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

    var glucoseValues: [Glucose] {
        get {
            return getArray(forKey: Keys.glucoseValues.rawValue) ?? []
        }
        set {
            setArray(newValue, forKey: Keys.glucoseValues.rawValue)
        }
    }
    
    var latestReadings: Data? {
        get {
            return data(forKey: Keys.latestReadings.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.latestReadings.rawValue)
            } else {
                removeObject(forKey: Keys.latestReadings.rawValue)
            }
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

    var nightscoutUpload: Bool {
        get {
            if object(forKey: Keys.nightscoutUpload.rawValue) != nil {
                return bool(forKey: Keys.nightscoutUpload.rawValue)
            }

            return false
        }
        set {
            set(newValue, forKey: Keys.nightscoutUpload.rawValue)
        }
    }
    
    var selectedCalendarTarget: String? {
        get {
            return string(forKey: Keys.selectedCalendarTarget.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.selectedCalendarTarget.rawValue)
            } else {
                removeObject(forKey: Keys.selectedCalendarTarget.rawValue)
            }
        }
    }

    
    var selectedConnectionId: String? {
        get {
            return string(forKey: Keys.selectedConnectionId.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.selectedConnectionId.rawValue)
            } else {
                removeObject(forKey: Keys.selectedConnectionId.rawValue)
            }
        }
    }

    var selectedView: Int {
        get {
            if object(forKey: Keys.selectedView.rawValue) != nil {
                return integer(forKey: Keys.selectedView.rawValue)
            }

            return 1
        }
        set {
            set(newValue, forKey: Keys.selectedView.rawValue)
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

    var transmitter: Transmitter? {
        get {
            return getObject(forKey: Keys.transmitter.rawValue)
        }
        set {
            if let newValue = newValue {
                setObject(newValue, forKey: Keys.transmitter.rawValue)
            } else {
                removeObject(forKey: Keys.transmitter.rawValue)
            }
        }
    }
}

extension UserDefaults {
    static let shared = UserDefaults(suiteName: stringValue(forKey: "APP_GROUP_ID"))!

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

    static func stringValue(forKey key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
        else {
            fatalError("Invalid value or undefined key")
        }
        return value
    }
}
