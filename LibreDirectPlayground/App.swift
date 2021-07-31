//
//  LibreDirectPlaygroundApp.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 06.07.21.
//

import SwiftUI
import CoreBluetooth

@main
final class LibreDirectApp: App {
    private let store: AppStore = AppStore(initialState: DefaultAppState(), reducer: defaultAppReducer, middlewares: [
            sensorPairingMiddelware(service: SensorPairingService()),
            sensorConnectionMiddelware(service: SensorConnectionService()),
            sensorExpiredAlertMiddelware(service: SensorExpiredAlertService()),
            sensorGlucoseAlertMiddelware(service: SensorGlucoseAlertService()),
            sensorGlucoseBadgeMiddelware(service: SensorGlucoseBadgeService()),
            sensorConnectionLostAlertMiddelware(service: SensorConnectionLostAlertService()),
            freeAPSMiddleware(service: FreeAPSService()),
            nightscoutMiddleware(service: NightscoutService()),
            widgetUpdaterMiddleware(),
            actionLogMiddleware()
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
