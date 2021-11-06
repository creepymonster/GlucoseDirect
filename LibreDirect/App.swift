//
//  App.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import CoreBluetooth
import SwiftUI

// MARK: - LibreDirectApp

@main
final class LibreDirectApp: App {
    // MARK: Lifecycle

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

    // MARK: Internal

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }

    // MARK: Private

    private let store = AppStore(initialState: DefaultAppState(), reducer: defaultAppReducer, middlewares: [
        // required middlewares
        actionLogMiddleware(),
        
        // sensor middleware
        libre2Middelware(),
        
        // other middlewares
        expiringNotificationMiddelware(),
        glucoseNotificationMiddelware(),
        glucoseBadgeMiddelware(),
        connectionNotificationMiddelware(),
        freeAPSMiddleware(),
        nightscoutMiddleware()
    ])

    private let notificationCenterDelegate = LibreDirectNotificationCenter()
}

// MARK: - LibreDirectNotificationCenter

final class LibreDirectNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .banner, .list, .sound])
    }
}
