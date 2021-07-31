//
//  NFC.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 06.07.21.
//

import Foundation
import Combine
import CoreNFC

struct SensorPairingInfo {
    private(set) var uuid: Data
    private(set) var patchInfo: Data
    private(set) var fram: Data
    private(set) var streamingEnabled: Bool
}

protocol SensorPairingProtocol {
    func pairSensor() -> AnyPublisher<SensorPairingInfo, Never>
}

func sensorPairingMiddelware(service: SensorPairingProtocol) -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .pairSensor:
            return service.pairSensor()
                .subscribe(on: DispatchQueue.main)
                .map { AppAction.setSensor(value: Sensor(uuid: $0.uuid, patchInfo: $0.patchInfo, fram: $0.fram)) }
                .eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}
