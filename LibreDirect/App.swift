//
//  App.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI
import CoreBluetooth
import LibreDirectLibrary

@main
final class LibreDirectApp: App {
    private let store: AppStore = AppStore(initialState: DefaultAppState(), reducer: defaultAppReducer, middlewares: [
            actionLogMiddleware(),
            libre2Middelware(),
            expiringNotificationMiddelware(),
            glucoseNotificationMiddelware(),
            glucoseNotificationMiddelware(),
            connectionNotificationMiddelware(),
            freeAPSMiddleware(),
            nightscoutMiddleware()
        ])

    private let notificationCenterDelegate = LibreDirectNotificationCenter()

    init() {
        UNUserNotificationCenter.current().delegate = notificationCenterDelegate

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

final class LibreDirectNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .banner, .list, .sound])
    }
}
