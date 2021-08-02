//
//  DummyAppState.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

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

struct PreviewAppState: AppState {
    var alarmHigh: Int = 180
    var alarmLow: Int = 70
    var alarmSnoozeUntil: Date? = nil
    var connectionError: String? = "Timeout"
    var connectionErrorTimeStamp: Date? = Date()
    var connectionState: SensorConnectionState = .connected
    var glucoseUnit: GlucoseUnit = GlucoseUnit.mgdL

    var glucoseValues: [SensorGlucose] = [
        SensorGlucose(timeStamp: Date().addingTimeInterval(-30 * 60), glucose: 60),
        SensorGlucose(timeStamp: Date().addingTimeInterval(-25 * 60), glucose: 65),
        SensorGlucose(timeStamp: Date().addingTimeInterval(-15 * 60), glucose: 70),
        SensorGlucose(timeStamp: Date().addingTimeInterval(-11 * 60), glucose: 75),
        SensorGlucose(timeStamp: Date().addingTimeInterval(-7 * 60), glucose: 80),
        SensorGlucose(timeStamp: Date().addingTimeInterval(-5 * 60), glucose: 85),
        SensorGlucose(timeStamp: Date().addingTimeInterval(-4 * 60), glucose: 90),
        SensorGlucose(timeStamp: Date().addingTimeInterval(-3 * 60), glucose: 100),
        SensorGlucose(timeStamp: Date().addingTimeInterval(-2 * 60), glucose: 120),
        SensorGlucose(timeStamp: Date().addingTimeInterval(-1 * 60), glucose: 110),
        SensorGlucose(timeStamp: Date(), glucose: 100)
    ]
    
    var nightscoutApiSecret: String = ""
    var nightscoutHost: String = ""
    var sensor: Sensor? = createPreviewSensor()
    
    var lastGlucose: SensorGlucose? {
        get {
            return glucoseValues.last
        }
    }
    
    var isPairable: Bool = true
    var isPaired: Bool = true
    var isConnectable: Bool = true
    var isDisconnectable: Bool = true
    var isReady: Bool = true
}

let previewSensor = createPreviewSensor()
