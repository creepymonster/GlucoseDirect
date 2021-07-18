//
//  LibreDirectPlaygroundApp.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI
import CoreBluetooth

@main
final class LibreDirectApp: App {
    private let store: AppStore = AppStore(initialState: DefaultAppState(), reducer: defaultAppReducer, middlewares: [
            sensorPairingMiddelware(service: SensorPairingService()),
            sensorConnectionMiddelware(service: SensorConnectionService()),
            sensorExpiredMiddelware(service: SensorExpiredService()),
            freeAPSMiddleware(service: FreeAPSService()),
            nightscoutMiddleware(service: NightscoutService()),
            printLogMiddleware(),
        ])

    init() {
        store.dispatch(.subscribeForUpdates)

        if store.state.isPaired {
            DispatchQueue.global(qos: .utility).async {
                Thread.sleep(forTimeInterval: 3)

                DispatchQueue.main.sync {
                    self.store.dispatch(.connectSensor)
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
