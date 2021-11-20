//
//  App.swift
//  LibreDirect
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
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                self.store.dispatch(.connectSensor)
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

    #if targetEnvironment(simulator) || targetEnvironment(macCatalyst)
    private let store = AppStore(initialState: SimulatorAppState(), reducer: simulatorAppReducer, middlewares: [
        // required middlewares
        actionLogMiddleware(),

        // other middlewares
        expiringNotificationMiddelware(),
        glucoseNotificationMiddelware(),
        glucoseBadgeMiddelware(),
        connectionNotificationMiddelware(),
        freeAPSMiddleware(),
        nightscoutMiddleware()
    ])
    #else
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
    #endif

    private let notificationCenterDelegate = LibreDirectNotificationCenter()
}

// MARK: - LibreDirectNotificationCenter

final class LibreDirectNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .banner, .list, .sound])
    }
}

