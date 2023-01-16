//
//  UserDefaults.swift
//  GlucoseDirect
//

import Foundation

// MARK: - Keys

private enum Keys: String {
    case appSerial = "libre-direct.settings.app-serial"
    case alarmHigh = "libre-direct.settings.alarm-high"
    case alarmLow = "libre-direct.settings.alarm-low"
    case alarmVolume = "libre-direct.settings.alarm-volume"
    case appleHealthExport = "libre-direct.settings.apple-health-export"
    case bellmanAlarm = "libre-direct.settings.bellman-alarm"
    case calendarExport = "libre-direct.settings.calendar-export"
    case chartShowLines = "libre-direct.settings.chart-show-lines"
    case chartZoomLevel = "libre-direct.settings.chart-zoom-level"
    case connectionAlarmSound = "libre-direct.settings.connection-alarm-sound"
    case connectionPeripheralUUID = "libre-direct.sensor-ble-connection.peripheral-uuid"
    case customCalibration = "libre-direct.settings.custom-calibration"
    case expiringAlarmSound = "libre-direct.settings.expiring-alarm-sound"
    case normalGlucoseNotification = "libre-direct.settings.normal-glucose-notification"
    case alarmGlucoseNotification = "libre-direct.settings.alarm-glucose-notification"
    case glucoseLiveActivity = "libre-direct.settings.glucose-live-activity"
    case glucoseUnit = "libre-direct.settings.glucose-unit"
    case highGlucoseAlarmSound = "libre-direct.settings.high-glucose-alarm-sound"
    case ignoreMute = "libre-direct.settings.ignore-mute"
    case isConnectionPaired = "libre-direct.settings.is-paired"
    case latestBloodGlucose = "libre-direct.settings.latest-blood-glucose"
    case latestSensorError = "libre-direct.settings.latest-sensor-error"
    case latestSensorGlucose = "libre-direct.settings.latest-sensor-glucose"
    case latestInsulinDelivery = "libre-direct.settings.latest-insulin-delivery"
    case lowGlucoseAlarmSound = "libre-direct.settings.low-glucose-alarm-sound"
    case nightscoutApiSecret = "libre-direct.settings.nightscout-api-secret"
    case nightscoutUpload = "libre-direct.settings.nightscout-upload-enabled"
    case nightscoutURL = "libre-direct.settings.nightscout-host"
    case readGlucose = "libre-direct.settings.read-glucose"
    case selectedCalendarTarget = "libre-direct.settings.selected-calendar-target"
    case selectedConnectionID = "libre-direct.settings.selected-connection-id"
    case sensor = "libre-direct.settings.sensor"
    case sensorInterval = "libre-direct.settings.sensor-interval"
    case sharedApp = "glucosedirect--app"
    case sharedAppVersion = "glucosedirect--app-version"
    case sharedGlucose = "latestReadings"
    case sharedSensor = "glucosedirect--sensor"
    case sharedSensorConnectionState = "glucosedirect--sensor-connection-state"
    case sharedSensorState = "glucosedirect--sensor-state"
    case sharedTransmitter = "glucosedirect--transmitter"
    case sharedTransmitterBattery = "glucosedirect--transmitter-battery"
    case sharedTransmitterFirmware = "glucosedirect--transmitter-firmware"
    case sharedTransmitterHardware = "glucosedirect--transmitter-hardware"
    case transmitter = "libre-direct.settings.transmitter"
    case showAnnotations = "libre-direct.settings.show-annotations"
    case showSmoothedGlucose = "libre-direct.settings.smooth-chart-values"
    case showInsulinInput = "libre-direct.settings.show-insulin-delivery-input"
}

extension UserDefaults {
    var appSerial: String {
        if let serial = string(forKey: Keys.appSerial.rawValue) {
            return serial
        }

        let newSerial = UUID().uuidString

        set(newSerial, forKey: Keys.alarmHigh.rawValue)

        return newSerial
    }

    var alarmHigh: Int {
        get {
            if object(forKey: Keys.alarmHigh.rawValue) != nil {
                return integer(forKey: Keys.alarmHigh.rawValue)
            }

            return 180
        }
        set {
            set(newValue, forKey: Keys.alarmHigh.rawValue)
        }
    }

    var alarmLow: Int {
        get {
            if object(forKey: Keys.alarmLow.rawValue) != nil {
                return integer(forKey: Keys.alarmLow.rawValue)
            }

            return 80
        }
        set {
            set(newValue, forKey: Keys.alarmLow.rawValue)
        }
    }

    var alarmVolume: Float {
        get {
            if object(forKey: Keys.alarmVolume.rawValue) != nil {
                return float(forKey: Keys.alarmVolume.rawValue)
            }

            return 0.2
        }
        set {
            set(newValue, forKey: Keys.alarmVolume.rawValue)
        }
    }

    var appleHealthExport: Bool {
        get {
            if object(forKey: Keys.appleHealthExport.rawValue) != nil {
                return bool(forKey: Keys.appleHealthExport.rawValue)
            }

            return false
        }
        set {
            set(newValue, forKey: Keys.appleHealthExport.rawValue)
        }
    }

    var bellmanAlarm: Bool {
        get {
            if object(forKey: Keys.bellmanAlarm.rawValue) != nil {
                return bool(forKey: Keys.bellmanAlarm.rawValue)
            }

            return false
        }
        set {
            set(newValue, forKey: Keys.bellmanAlarm.rawValue)
        }
    }

    var ignoreMute: Bool {
        get {
            if object(forKey: Keys.ignoreMute.rawValue) != nil {
                return bool(forKey: Keys.ignoreMute.rawValue)
            }

            return false
        }
        set {
            set(newValue, forKey: Keys.ignoreMute.rawValue)
        }
    }

    var appleCalendarExport: Bool {
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

    var chartZoomLevel: Int {
        get {
            if object(forKey: Keys.chartZoomLevel.rawValue) != nil {
                return integer(forKey: Keys.chartZoomLevel.rawValue)
            }

            return 3
        }
        set {
            set(newValue, forKey: Keys.chartZoomLevel.rawValue)
        }
    }

    var connectionPeripheralUUID: String? {
        get {
            return string(forKey: Keys.connectionPeripheralUUID.rawValue)
        }
        set {
            if let newValue = newValue {
                setValue(newValue, forKey: Keys.connectionPeripheralUUID.rawValue)
            } else {
                removeObject(forKey: Keys.connectionPeripheralUUID.rawValue)
            }
        }
    }

    var connectionAlarmSound: NotificationSound {
        get {
            if let soundRawValue = object(forKey: Keys.connectionAlarmSound.rawValue) as? String, let sound = NotificationSound(rawValue: soundRawValue) {
                return sound
            }

            return .alarm
        }
        set {
            set(newValue.rawValue, forKey: Keys.connectionAlarmSound.rawValue)
        }
    }

    var customCalibration: [CustomCalibration] {
        get {
            return getArray(forKey: Keys.customCalibration.rawValue) ?? []
        }
        set {
            setArray(newValue, forKey: Keys.customCalibration.rawValue)
        }
    }

    var expiringAlarmSound: NotificationSound {
        get {
            if let soundRawValue = object(forKey: Keys.expiringAlarmSound.rawValue) as? String, let sound = NotificationSound(rawValue: soundRawValue) {
                return sound
            }

            return .expiring
        }
        set {
            set(newValue.rawValue, forKey: Keys.expiringAlarmSound.rawValue)
        }
    }

    var highGlucoseAlarmSound: NotificationSound {
        get {
            if let soundRawValue = object(forKey: Keys.highGlucoseAlarmSound.rawValue) as? String, let sound = NotificationSound(rawValue: soundRawValue) {
                return sound
            }

            return .alarm
        }
        set {
            set(newValue.rawValue, forKey: Keys.highGlucoseAlarmSound.rawValue)
        }
    }

    var lowGlucoseAlarmSound: NotificationSound {
        get {
            if let soundRawValue = object(forKey: Keys.lowGlucoseAlarmSound.rawValue) as? String, let sound = NotificationSound(rawValue: soundRawValue) {
                return sound
            }

            return .alarm
        }
        set {
            set(newValue.rawValue, forKey: Keys.lowGlucoseAlarmSound.rawValue)
        }
    }

    var normalGlucoseNotification: Bool {
        get {
            if object(forKey: Keys.normalGlucoseNotification.rawValue) != nil {
                return bool(forKey: Keys.normalGlucoseNotification.rawValue)
            }

            return true
        }
        set {
            set(newValue, forKey: Keys.normalGlucoseNotification.rawValue)
        }
    }

    var alarmGlucoseNotification: Bool {
        get {
            if object(forKey: Keys.alarmGlucoseNotification.rawValue) != nil {
                return bool(forKey: Keys.alarmGlucoseNotification.rawValue)
            }

            return normalGlucoseNotification
        }
        set {
            set(newValue, forKey: Keys.alarmGlucoseNotification.rawValue)
        }
    }

    var glucoseLiveActivity: Bool {
        get {
            if object(forKey: Keys.glucoseLiveActivity.rawValue) != nil {
                return bool(forKey: Keys.glucoseLiveActivity.rawValue)
            }

            return false
        }
        set {
            set(newValue, forKey: Keys.glucoseLiveActivity.rawValue)
        }
    }

    var glucoseUnit: GlucoseUnit? {
        get {
            if let glucoseUnitValue = object(forKey: Keys.glucoseUnit.rawValue) as? String {
                return GlucoseUnit(rawValue: glucoseUnitValue)!
            }

            return nil
        }
        set {
            if let newValue = newValue {
                set(newValue.rawValue, forKey: Keys.glucoseUnit.rawValue)
            } else {
                removeObject(forKey: Keys.glucoseUnit.rawValue)
            }
        }
    }

    var isConnectionPaired: Bool {
        get {
            if object(forKey: Keys.isConnectionPaired.rawValue) != nil {
                return bool(forKey: Keys.isConnectionPaired.rawValue)
            }

            return false
        }
        set {
            set(newValue, forKey: Keys.isConnectionPaired.rawValue)
        }
    }

    var latestBloodGlucose: BloodGlucose? {
        get {
            return getObject(forKey: Keys.latestBloodGlucose.rawValue)
        }
        set {
            if let newValue = newValue {
                setObject(newValue, forKey: Keys.latestBloodGlucose.rawValue)
            } else {
                removeObject(forKey: Keys.latestBloodGlucose.rawValue)
            }
        }
    }

    var latestSensorGlucose: SensorGlucose? {
        get {
            return getObject(forKey: Keys.latestSensorGlucose.rawValue)
        }
        set {
            if let newValue = newValue {
                setObject(newValue, forKey: Keys.latestSensorGlucose.rawValue)
            } else {
                removeObject(forKey: Keys.latestSensorGlucose.rawValue)
            }
        }
    }

    var latestSensorError: SensorError? {
        get {
            return getObject(forKey: Keys.latestSensorError.rawValue)
        }
        set {
            if let newValue = newValue {
                setObject(newValue, forKey: Keys.latestSensorError.rawValue)
            } else {
                removeObject(forKey: Keys.latestSensorError.rawValue)
            }
        }
    }

    var latestInsulinDelivery: InsulinDelivery? {
        get {
            return getObject(forKey: Keys.latestInsulinDelivery.rawValue)
        }
        set {
            if let newValue = newValue {
                setObject(newValue, forKey: Keys.latestInsulinDelivery.rawValue)
            } else {
                removeObject(forKey: Keys.latestInsulinDelivery.rawValue)
            }
        }
    }

    var sharedGlucose: Data? {
        get {
            return data(forKey: Keys.sharedGlucose.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.sharedGlucose.rawValue)
            } else {
                removeObject(forKey: Keys.sharedGlucose.rawValue)
            }
        }
    }

    var sharedSensor: String? {
        get {
            return string(forKey: Keys.sharedSensor.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.sharedSensor.rawValue)
            } else {
                removeObject(forKey: Keys.sharedSensor.rawValue)
            }
        }
    }

    var sharedSensorState: String? {
        get {
            return string(forKey: Keys.sharedSensorState.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.sharedSensorState.rawValue)
            } else {
                removeObject(forKey: Keys.sharedSensorState.rawValue)
            }
        }
    }

    var sharedSensorConnectionState: String? {
        get {
            return string(forKey: Keys.sharedSensorConnectionState.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.sharedSensorConnectionState.rawValue)
            } else {
                removeObject(forKey: Keys.sharedSensorConnectionState.rawValue)
            }
        }
    }

    var sharedApp: String? {
        get {
            return string(forKey: Keys.sharedApp.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.sharedApp.rawValue)
            } else {
                removeObject(forKey: Keys.sharedApp.rawValue)
            }
        }
    }

    var sharedAppVersion: String? {
        get {
            return string(forKey: Keys.sharedAppVersion.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.sharedAppVersion.rawValue)
            } else {
                removeObject(forKey: Keys.sharedAppVersion.rawValue)
            }
        }
    }

    var sharedTransmitter: String? {
        get {
            return string(forKey: Keys.sharedTransmitter.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.sharedTransmitter.rawValue)
            } else {
                removeObject(forKey: Keys.sharedTransmitter.rawValue)
            }
        }
    }

    var sharedTransmitterBattery: String? {
        get {
            return string(forKey: Keys.sharedTransmitterBattery.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.sharedTransmitterBattery.rawValue)
            } else {
                removeObject(forKey: Keys.sharedTransmitterBattery.rawValue)
            }
        }
    }

    var sharedTransmitterHardware: String? {
        get {
            return string(forKey: Keys.sharedTransmitterHardware.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.sharedTransmitterHardware.rawValue)
            } else {
                removeObject(forKey: Keys.sharedTransmitterHardware.rawValue)
            }
        }
    }

    var sharedTransmitterFirmware: String? {
        get {
            return string(forKey: Keys.sharedTransmitterFirmware.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.sharedTransmitterFirmware.rawValue)
            } else {
                removeObject(forKey: Keys.sharedTransmitterFirmware.rawValue)
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

    var nightscoutURL: String {
        get {
            return string(forKey: Keys.nightscoutURL.rawValue) ?? ""
        }
        set {
            if newValue.isEmpty {
                removeObject(forKey: Keys.nightscoutURL.rawValue)
            } else {
                set(newValue, forKey: Keys.nightscoutURL.rawValue)
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

    var readGlucose: Bool {
        get {
            if object(forKey: Keys.readGlucose.rawValue) != nil {
                return bool(forKey: Keys.readGlucose.rawValue)
            }

            return false
        }
        set {
            set(newValue, forKey: Keys.readGlucose.rawValue)
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

    var selectedConnectionID: String? {
        get {
            return string(forKey: Keys.selectedConnectionID.rawValue)
        }
        set {
            if let newValue = newValue {
                set(newValue, forKey: Keys.selectedConnectionID.rawValue)
            } else {
                removeObject(forKey: Keys.selectedConnectionID.rawValue)
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

    var sensorInterval: Int {
        get {
            if object(forKey: Keys.sensorInterval.rawValue) != nil {
                return integer(forKey: Keys.sensorInterval.rawValue)
            }

            return 1
        }
        set {
            set(newValue, forKey: Keys.sensorInterval.rawValue)
        }
    }

    var showAnnotations: Bool {
        get {
            if object(forKey: Keys.showAnnotations.rawValue) != nil {
                return bool(forKey: Keys.showAnnotations.rawValue)
            }

            return true
        }
        set {
            set(newValue, forKey: Keys.showAnnotations.rawValue)
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

    var showSmoothedGlucose: Bool {
        get {
            if object(forKey: Keys.showSmoothedGlucose.rawValue) != nil {
                return bool(forKey: Keys.showSmoothedGlucose.rawValue)
            }

            return false
        }
        set {
            set(newValue, forKey: Keys.showSmoothedGlucose.rawValue)
        }
    }

    var showInsulinInput: Bool {
        get {
            if object(forKey: Keys.showInsulinInput.rawValue) != nil {
                return bool(forKey: Keys.showInsulinInput.rawValue)
            }

            return true
        }
        set {
            set(newValue, forKey: Keys.showInsulinInput.rawValue)
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
        guard let data = data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode([Element].self, from: data)
    }

    func setObject<Element>(_ obj: Element, forKey key: String) where Element: Encodable {
        let data = try? JSONEncoder().encode(obj)
        set(data, forKey: key)
    }

    func getObject<Element>(forKey key: String) -> Element? where Element: Decodable {
        guard let data = data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(Element.self, from: data)
    }

    static func stringValue(forKey key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("Invalid value or undefined key")
        }

        return value
    }
}
