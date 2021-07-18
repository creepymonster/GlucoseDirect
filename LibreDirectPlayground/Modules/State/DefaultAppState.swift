//
//  DefaultAppState.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

struct DefaultAppState: AppState {
    var appGroupName: String? = "group.reimarmetzen.FreeAPS"

    var connectionState: SensorConnectionState = .disconnected
    var connectionError: String?
    var glucoseTrend: [SensorGlucose] = []

    var nightscoutHost: String = "" {
        didSet {
            if nightscoutHost.isEmpty {
                UserDefaults.standard.removeObject(forKey: Key.nightscoutHost.rawValue)
            } else {
                UserDefaults.standard.set(nightscoutHost, forKey: Key.nightscoutHost.rawValue)
            }
        }
    }

    var nightscoutApiSecret: String = "" {
        didSet {
            if nightscoutApiSecret.isEmpty {
                UserDefaults.standard.removeObject(forKey: Key.nightscoutApiSecret.rawValue)
            } else {
                UserDefaults.standard.set(nightscoutApiSecret, forKey: Key.nightscoutApiSecret.rawValue)
            }
        }
    }

    var sensor: Sensor? = nil {
        didSet {
            if let sensor = sensor {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(sensor) {
                    UserDefaults.standard.set(encoded, forKey: Key.sensor.rawValue)
                }
            } else {
                UserDefaults.standard.removeObject(forKey: Key.sensor.rawValue)
            }
        }
    }

    init() {
        if let nightscoutHost = UserDefaults.standard.string(forKey: Key.nightscoutHost.rawValue) {
            self.nightscoutHost = nightscoutHost
        }

        if let apiSecret = UserDefaults.standard.string(forKey: Key.nightscoutApiSecret.rawValue) {
            self.nightscoutApiSecret = apiSecret.toSha1()
        }

        if let savedSensor = UserDefaults.standard.object(forKey: Key.sensor.rawValue) as? Data {
            let decoder = JSONDecoder()

            if let sensor = try? decoder.decode(Sensor.self, from: savedSensor) {
                self.sensor = sensor
            }
        }
    }

    init(connectionState: SensorConnectionState, sensor: Sensor, glucoseTrend: [SensorGlucose] = []) {
        self.connectionState = connectionState
        self.sensor = sensor
        self.glucoseTrend = glucoseTrend
    }
}

extension DefaultAppState {
    private static var connectableStates: Set<SensorConnectionState> = [.disconnected]
    private static var disconnectableStates: Set<SensorConnectionState> = [.connected, .connecting, .scanning]

    var isPairable: Bool {
        get {
            return sensor == nil
        }
    }

    var isPaired: Bool {
        get {
            return sensor != nil
        }
    }

    var isConnectable: Bool {
        get {
            return DefaultAppState.connectableStates.contains(connectionState)
        }
    }

    var isDisconnectable: Bool {
        get {
            return DefaultAppState.disconnectableStates.contains(connectionState)
        }
    }

    var isReady: Bool {
        get {
            return sensor != nil && sensor!.state == .ready
        }
    }
}

fileprivate enum Key: String, CaseIterable {
    case sensor = "libre-direct.settings.sensor"
    case nightscoutHost = "libre-direct.settings.nightscout-host"
    case nightscoutApiSecret = "libre-direct.settings.nightscout-api-secret"
}
