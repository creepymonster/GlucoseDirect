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
            dataStoreMigrationMiddleware(),
            bloodGlucoseStoreMiddleware(),
            sensorGlucoseStoreMiddleware(),
            sensorErrorStoreMiddleware(),
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
            sensorErrorMiddleware(),
        ]

        middlewares.append(sensorConnectorMiddelware([
            SensorConnectionInfo(id: DirectConfig.virtualID, name: "Virtual") { VirtualLibreConnection(subject: $0) },
        ]))

        #if DEBUG
            middlewares.append(debugMiddleware())
        #endif

        return DirectStore(initialState: AppState(), reducer: directReducer, middlewares: middlewares)
    }

    private static func createAppStore() -> DirectStore {
        DirectLog.info("Create app store")

        var middlewares = [
            logMiddleware(),
            dataStoreMigrationMiddleware(),
            bloodGlucoseStoreMiddleware(),
            sensorGlucoseStoreMiddleware(),
            sensorErrorStoreMiddleware(),
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
            sensorErrorMiddleware(),
        ]

        var connectionInfos: [SensorConnectionInfo] = []

        #if canImport(CoreNFC)
            if NFCTagReaderSession.readingAvailable {
                connectionInfos.append(SensorConnectionInfo(id: DirectConfig.libre2ID, name: LocalizedString("Without transmitter"), connectionCreator: { Libre2Connection(subject: $0) }))
                connectionInfos.append(SensorConnectionInfo(id: DirectConfig.bubbleID, name: LocalizedString("Bubble transmitter"), connectionCreator: { BubbleConnection(subject: $0) }))
            } else {
                connectionInfos.append(SensorConnectionInfo(id: DirectConfig.bubbleID, name: LocalizedString("Bubble transmitter"), connectionCreator: { BubbleConnection(subject: $0) }))
            }
        #else
            connectionInfos.append(SensorConnectionInfo(id: DirectConfig.bubbleID, name: LocalizedString("Bubble transmitter"), connectionCreator: { BubbleConnection(subject: $0) }))
        #endif

        #if DEBUG
            connectionInfos.append(SensorConnectionInfo(id: DirectConfig.librelinkID, name: LocalizedString("LibreLink transmitter"), connectionCreator: { LibreLinkConnection(subject: $0) }))
        #endif

        middlewares.append(sensorConnectorMiddelware(connectionInfos))

        #if DEBUG
            middlewares.append(debugMiddleware())
        #endif

        return DirectStore(initialState: AppState(), reducer: directReducer, middlewares: middlewares)
    }
}

// MARK: - GlucoseDirectNotificationCenter

class GlucoseDirectNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
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
            store.dispatch(.selectView(viewTag: DirectConfig.overviewViewTag))
            store.dispatch(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(30 * 60).toRounded(on: 1, .minute)))
        }

        completionHandler()
    }

    // MARK: Private

    private weak var store: DirectStore?
}

// MARK: - GlucoseDirectAppDelegate

class GlucoseDirectAppDelegate: NSObject, UIApplicationDelegate {
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
