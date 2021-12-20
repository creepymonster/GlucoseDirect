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

    @UIApplicationDelegateAdaptor(LibreDirectAppDelegate.self) var delegate

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
            AppLog.info("start preview mode")

            return createPreviewStore()
        }

        return createAppStore()
    }

    private static func createPreviewStore() -> AppStore {
        return AppStore(initialState: MemoryAppState(), reducer: appReducer, middlewares: [
            // required middlewares
            logMiddleware(),
            sensorConnectorMiddelware([
                SensorConnectionInfo(id: "virtual", name: "Virtual") { VirtualLibreConnection(subject: $0) },
            ]),

            // notification middleswares
            expiringNotificationMiddelware(),
            glucoseNotificationMiddelware(),
            connectionNotificationMiddelware(),
            calendarExportMiddleware(),
        ])
    }

    private static func createAppStore() -> AppStore {
        return AppStore(initialState: StoredAppState(), reducer: appReducer, middlewares: [
            // required middlewares
            logMiddleware(),
            sensorConnectorMiddelware([
                SensorConnectionInfo(id: "libre2", name: LocalizedString("Without transmitter")) { Libre2Connection(subject: $0) },
                SensorConnectionInfo(id: "bubble", name: LocalizedString("Bubble transmitter")) { BubbleConnection(subject: $0) },
            ]),

            // notification middleswares
            expiringNotificationMiddelware(),
            glucoseNotificationMiddelware(),
            connectionNotificationMiddelware(),
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

// MARK: - LibreDirectAppDelegate

final class LibreDirectAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        AppLog.info("Application did finish launching with options")
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AppLog.info("Application will terminate")
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        AppLog.info("Application did receive memory warning")
    }
}
