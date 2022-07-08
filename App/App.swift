//
//  App.swift
//  GlucoseDirect
//

import CoreBluetooth
import SwiftUI

#if canImport(CoreNFC)
    import CoreNFC
#endif

// MARK: - GlucoseDirectApp

@main
final class GlucoseDirectApp: App {
    // MARK: Lifecycle

    init() {
        store = GlucoseDirectApp.createStore()

        notificationCenterDelegate = GlucoseDirectNotificationCenter(store: store)
        UNUserNotificationCenter.current().delegate = notificationCenterDelegate

        store.dispatch(.startup)
    }

    deinit {
        UNUserNotificationCenter.current().delegate = nil
    }

    // MARK: Internal

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }

    @UIApplicationDelegateAdaptor(GlucoseDirectAppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }

    // MARK: Private

    private let store: DirectStore
    private let notificationCenterDelegate: UNUserNotificationCenterDelegate

    private static func createStore() -> DirectStore {
        if isSimulator {
            return createSimulatorAppStore()
        }

        return createAppStore()
    }

    private static func createSimulatorAppStore() -> DirectStore {
        DirectLog.info("Create preview store")

        var middlewares = [
            logMiddleware(),
            glucoseStoreMiddleware(),
            expiringNotificationMiddelware(),
            glucoseNotificationMiddelware(),
            connectionNotificationMiddelware(),
            appleCalendarExportMiddleware(),
            appleHealthExportMiddleware(),
            readAloudMiddelware(),
            bellmanAlarmMiddelware(),
            nightscoutMiddleware(),
            appGroupSharingMiddleware(),
            widgetCenterMiddleware(),
            screenLockMiddleware(),
        ]

        middlewares.append(sensorConnectorMiddelware([
            SensorConnectionInfo(id: "virtual", name: "Virtual") { VirtualLibreConnection(subject: $0) },
        ]))

        return DirectStore(initialState: AppState(), reducer: directReducer, middlewares: middlewares)
    }

    private static func createAppStore() -> DirectStore {
        DirectLog.info("Create app store")

        var middlewares = [
            logMiddleware(),
            glucoseStoreMiddleware(),
            expiringNotificationMiddelware(),
            glucoseNotificationMiddelware(),
            connectionNotificationMiddelware(),
            appleCalendarExportMiddleware(),
            appleHealthExportMiddleware(),
            readAloudMiddelware(),
            bellmanAlarmMiddelware(),
            nightscoutMiddleware(),
            appGroupSharingMiddleware(),
            widgetCenterMiddleware(),
            screenLockMiddleware(),
        ]

        let bubbleTransmitter = LocalizedString("Bubble transmitter")

        #if canImport(CoreNFC)
            if NFCTagReaderSession.readingAvailable {
                middlewares.append(sensorConnectorMiddelware([
                    SensorConnectionInfo(id: "libre2", name: LocalizedString("Without transmitter")) { Libre2Connection(subject: $0) },
                    // SensorConnectionInfo(id: "librelink", name: LocalizedString("LibreLink transmitter")) { LibreLinkConnection(subject: $0) },
                    SensorConnectionInfo(id: "bubble", name: bubbleTransmitter) { BubbleConnection(subject: $0) },
                ]))
            } else {
                middlewares.append(sensorConnectorMiddelware([
                    SensorConnectionInfo(id: "bubble", name: bubbleTransmitter) { BubbleConnection(subject: $0) },
                ]))
            }
        #else
            middlewares.append(sensorConnectorMiddelware([
                SensorConnectionInfo(id: "bubble", name: bubbleTransmitter) { BubbleConnection(subject: $0) },
            ]))
        #endif

        return DirectStore(initialState: AppState(), reducer: directReducer, middlewares: middlewares)
    }
}

// MARK: - GlucoseDirectNotificationCenter

final class GlucoseDirectNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    // MARK: Lifecycle

    init(store: DirectStore) {
        self.store = store
    }

    // MARK: Internal

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let store = store, let action = response.notification.request.content.userInfo["action"] as? String, action == "snooze" {
            DirectNotifications.shared.stopSound()
            store.dispatch(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(30 * 60).toRounded(on: 1, .minute)))
        }

        completionHandler()
    }

    // MARK: Private

    private weak var store: DirectStore?
}

// MARK: - GlucoseDirectAppDelegate

final class GlucoseDirectAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        DirectLog.info("Application did finish launching with options")
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DirectLog.info("Application will terminate")
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        DirectLog.info("Application did receive memory warning")
    }
}
