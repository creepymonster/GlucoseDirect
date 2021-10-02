//
//  PreviewAppState.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation
import Combine

public struct PreviewAppState: AppState {
    public var alarmHigh: Int = 180
    public var alarmLow: Int = 70
    public var alarmSnoozeUntil: Date? = nil
    public var connectionError: String? = "Timeout"
    public var connectionErrorTimeStamp: Date? = Date()
    public var connectionState: SensorConnectionState = .connected
    public var glucoseUnit: GlucoseUnit = GlucoseUnit.mgdL
    public var glucoseValues: [SensorGlucose] = [
        SensorGlucose(timestamp: Date().addingTimeInterval(-30 * 60), glucose: 60),
        SensorGlucose(timestamp: Date().addingTimeInterval(-25 * 60), glucose: 65),
        SensorGlucose(timestamp: Date().addingTimeInterval(-15 * 60), glucose: 70),
        SensorGlucose(timestamp: Date().addingTimeInterval(-11 * 60), glucose: 75),
        SensorGlucose(timestamp: Date().addingTimeInterval(-7 * 60), glucose: 80),
        SensorGlucose(timestamp: Date().addingTimeInterval(-5 * 60), glucose: 85),
        SensorGlucose(timestamp: Date().addingTimeInterval(-4 * 60), glucose: 90),
        SensorGlucose(timestamp: Date().addingTimeInterval(-3 * 60), glucose: 100),
        SensorGlucose(timestamp: Date().addingTimeInterval(-2 * 60), glucose: 120),
        SensorGlucose(timestamp: Date().addingTimeInterval(-1 * 60), glucose: 110),
        SensorGlucose(timestamp: Date(), glucose: 100)
    ]

    public var missedReadings: Int = 0
    public var nightscoutUpload: Bool = false
    public var nightscoutApiSecret: String = ""
    public var nightscoutHost: String = ""
    public var sensor: Sensor? = createPreviewSensor()
    public var deviceInfo: DeviceInfo? = nil
    
    public var lastGlucose: SensorGlucose? {
        get {
            return glucoseValues.last
        }
    }

    public init() {
    }
}

public let previewSensor = createPreviewSensor()

// MARK: - fileprivate
fileprivate let savedUuid = "phFxAgCkB+A=".fromBase64()!
fileprivate let savedPatchInfo = "nQgwAekK".fromBase64()!
fileprivate let savedFram = "X4XlsiPXmEs16xz6olwbLkv3oy3TOjZ+Ed7R5MnhG26v5sInIkWrsuYJ9Mv1EF25A78WrFhw+EtMKk+KHmUTaxQwjvsyoxk9hd7CB20u4CJmYlnWnApQDjsRBgvkMhySPAck9HZSS8xz+jTK28fxaSfg/VP/i8k/QpfaO4k9901nwybpFKKB7VuPKaTI1eqLqE/KZ0CwdAxgSfZ2+t5oJuVR1ZnVEKtyyhAe/1iE+8urILQtcGNLK9ych5DrVJGq2OVk34A0Tb9uzV+FRG2Smt/Xlthp35jM9cTtp52lSCjruGB2qe/4AOZL7J4HFOGoZesOhcp3bq0qanWg7PWFeRlzlmLDp+Qs4zbaLo0odgjAIlf9bqoHHMorR9aylxOEJNuk9cz1W3z32m2rFZzl3TbC0Ig4BruLx4v2WP2uIgkLySWOwdiSCEeoklMKWECaI/6hBCGrOxk=".fromBase64()!
fileprivate let savedSensor = "eyJmYW1pbHkiOjMsInJlZ2lvbiI6IjEgLSBFdXJvcGVhbiIsInNlcmlhbCI6IjNNSDAwNVZQUlo4IiwicGF0Y2hJbmZvIjoiblFnd0FaYzIiLCJjYWxpYnJhdGlvbiI6eyJpMyI6MTgsImk2Ijo3NDI4LCJpMiI6NzA1LCJpNSI6OTY2NCwiaTEiOjAsImk0Ijo2Nzc4fSwiYWdlIjoxOTc5MiwidXVpZCI6Iit0anVBZ0NrQitBPSIsImxpZmV0aW1lIjoyMDc1NCwidHlwZSI6IkxpYnJlIDIiLCJzdGF0ZSI6IlNlbnNvciBpcyByZWFkeSJ9".fromBase64()!

fileprivate func createPreviewSensor() -> Sensor {
    let decoder = JSONDecoder()

    if let sensor = try? decoder.decode(Sensor.self, from: savedSensor) {
        return sensor
    }

    return Sensor(uuid: savedUuid, patchInfo: savedPatchInfo, fram: savedFram)
}
