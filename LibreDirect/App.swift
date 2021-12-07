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
        store = LibreDirectApp.createStore()
        notificationCenterDelegate = LibreDirectNotificationCenter(store: store)

        UNUserNotificationCenter.current().delegate = notificationCenterDelegate
        store.dispatch(.startup)
    }

    // MARK: Internal

    static var isPreviewMode: Bool {
        return UserDefaults.standard.bool(forKey: "preview_mode")
    }

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }

    // MARK: Private

    private let store: AppStore
    private let notificationCenterDelegate: UNUserNotificationCenterDelegate

    private static func createStore() -> AppStore {
        if isSimulator || isPreviewMode {
            Log.info("start preview mode")

            return createPreviewStore()
        }

        return createAppStore()
    }

    private static func createPreviewStore() -> AppStore {
        return AppStore(initialState: InMemoryAppState(), reducer: appReducer, middlewares: [
            // required middlewares
            actionLogMiddleware(),
            sensorConnectorMiddelware([
                SensorConnectionInfo(id: "virtual", name: "Virtual") { VirtualLibreConnection() },
            ]),

            // notification middleswares
            expiringNotificationMiddelware(),
            glucoseNotificationMiddelware(),
            connectionNotificationMiddelware(),
            glucoseBadgeMiddelware(),
            calendarExportMiddleware(),
        ])
    }

    private static func createAppStore() -> AppStore {
        return AppStore(initialState: UserDefaultsAppState(), reducer: appReducer, middlewares: [
            // required middlewares
            actionLogMiddleware(),
            sensorConnectorMiddelware([
                SensorConnectionInfo(id: "libre2", name: LocalizedString("Without transmitter")) { Libre2Connection() },
                SensorConnectionInfo(id: "bubble", name: LocalizedString("Bubble transmitter")) { BubbleConnection() },
            ]),

            // notification middleswares
            expiringNotificationMiddelware(),
            glucoseNotificationMiddelware(),
            connectionNotificationMiddelware(),
            glucoseBadgeMiddelware(),
            calendarExportMiddleware(),

            // export middlewares
            nightscoutMiddleware(),
            appGroupSharingMiddleware(),
        ])
    }
}

// MARK: - LibreDirectNotificationCenter

final class LibreDirectNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    // MARK: Lifecycle

    init(store: AppStore) {
        self.store = store
    }

    // MARK: Internal

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let store = store, let action = response.notification.request.content.userInfo["action"] as? String, action == "snooze" {
            store.dispatch(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(30 * 60).rounded(on: 1, .minute)))
        }

        completionHandler()
    }

    // MARK: Private

    private weak var store: AppStore?
}
