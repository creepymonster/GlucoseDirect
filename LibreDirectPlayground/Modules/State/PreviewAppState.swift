//
//  DummyAppState.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

struct PreviewAppState: AppState {
    var appGroupName: String? = nil
    var connectionError: String? = nil
    var connectionState: SensorConnectionState = .connected
    var glucoseTrend: [SensorGlucose] = [SensorGlucose(id: 1, timeStamp: Date(), glucose: 100, trend: .constant)]
    var nightscoutApiSecret: String = ""
    var nightscoutHost: String = ""
    var sensor: Sensor? = Sensor(uuid: uuid, patchInfo: patchInfo, fram: fram)

    var isPairable: Bool = true
    var isPaired: Bool = true
    var isConnectable: Bool = true
    var isDisconnectable: Bool = true
    var isReady: Bool = true
}

fileprivate let uuid = "phFxAgCkB+A=".fromBase64()!
fileprivate let patchInfo = "nQgwAekK".fromBase64()!
fileprivate let fram = "X4XlsiPXmEs16xz6olwbLkv3oy3TOjZ+Ed7R5MnhG26v5sInIkWrsuYJ9Mv1EF25A78WrFhw+EtMKk+KHmUTaxQwjvsyoxk9hd7CB20u4CJmYlnWnApQDjsRBgvkMhySPAck9HZSS8xz+jTK28fxaSfg/VP/i8k/QpfaO4k9901nwybpFKKB7VuPKaTI1eqLqE/KZ0CwdAxgSfZ2+t5oJuVR1ZnVEKtyyhAe/1iE+8urILQtcGNLK9ych5DrVJGq2OVk34A0Tb9uzV+FRG2Smt/Xlthp35jM9cTtp52lSCjruGB2qe/4AOZL7J4HFOGoZesOhcp3bq0qanWg7PWFeRlzlmLDp+Qs4zbaLo0odgjAIlf9bqoHHMorR9aylxOEJNuk9cz1W3z32m2rFZzl3TbC0Ig4BruLx4v2WP2uIgkLySWOwdiSCEeoklMKWECaI/6hBCGrOxk=".fromBase64()!
