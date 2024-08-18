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
struct GlucoseDirectApp: App {
    // MARK: Lifecycle

    init() {
        #if targetEnvironment(simulator)
            DirectLog.info("Application directory: \(NSHomeDirectory())")
        #endif

        store.dispatch(.startup)
    }

    // MARK: Internal

    @UIApplicationDelegateAdaptor(GlucoseDirectAppDelegate.self) var appDelegate {
        didSet {
            oldValue.store = nil
            appDelegate.store = store
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.store)
        }
    }

    // MARK: Private

    private let store: DirectStore = createStore()
}

// MARK: - GlucoseDirectAppDelegate

class GlucoseDirectAppDelegate: NSObject, UIApplicationDelegate {
    weak var store: DirectStore?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        DirectLog.info("Application did finish launching")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        DirectLog.info("Application did finish launching with options")

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DirectLog.info("Application will terminate")

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = nil

        if let store = store {
            store.dispatch(.shutdown)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        DirectLog.info("Application did enter background")
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        DirectLog.info("Application did receive memory warning")
    }
}

// MARK: UNUserNotificationCenterDelegate

extension GlucoseDirectAppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        DirectLog.info("Application will present notification")

        completionHandler([.badge, .banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        DirectLog.info("Application did receive notification response")

        if let store = store, let action = response.notification.request.content.userInfo["action"] as? String, action == "snooze" {
            store.dispatch(.selectView(viewTag: DirectConfig.overviewViewTag))
            store.dispatch(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(30 * 60).toRounded(on: 1, .minute)))
        }

        completionHandler()
    }
}

private func createStore() -> DirectStore {
    #if targetEnvironment(simulator)
        return createSimulatorAppStore()
    #else
        return createAppStore()
    #endif
}

private func createSimulatorAppStore() -> DirectStore {
    DirectLog.info("Create preview store")

    var middlewares = [
        logMiddleware(),
        dataStoreMigrationMiddleware(),
        bloodGlucoseStoreMiddleware(),
        sensorGlucoseStoreMiddleware(),
        sensorErrorStoreMiddleware(),
        insulinDeliveryStoreMiddleware(),
        glucoseStatisticsMiddleware(),
        expiringNotificationMiddelware(),
        glucoseNotificationMiddelware(),
        connectionNotificationMiddelware(),
        appleCalendarExportMiddleware(),
        appleHealthExportMiddleware(),
        readAloudMiddelware(),
        bellmanAlarmMiddelware(),
        nightscoutMiddleware(),
        appGroupSharingMiddleware(),
        screenLockMiddleware(),
        sensorErrorMiddleware(),
        storeExportMiddleware()
    ]

    if #available(iOS 16.1, *) {
        middlewares.append(widgetCenterMiddleware())
    }

    middlewares.append(sensorConnectorMiddelware([
        SensorConnectionInfo(id: DirectConfig.virtualID, name: "Virtual") { VirtualLibreConnection(subject: $0) }
    ]))

    if DirectConfig.isDebug {
        middlewares.append(debugMiddleware())
    }

    return DirectStore(initialState: AppState(), reducer: directReducer, middlewares: middlewares)
}

private func createAppStore() -> DirectStore {
    DirectLog.info("Create app store")

    var middlewares = [
        logMiddleware(),
        dataStoreMigrationMiddleware(),
        bloodGlucoseStoreMiddleware(),
        sensorGlucoseStoreMiddleware(),
        sensorErrorStoreMiddleware(),
        insulinDeliveryStoreMiddleware(),
        glucoseStatisticsMiddleware(),
        expiringNotificationMiddelware(),
        glucoseNotificationMiddelware(),
        connectionNotificationMiddelware(),
        appleCalendarExportMiddleware(),
        appleHealthExportMiddleware(),
        readAloudMiddelware(),
        bellmanAlarmMiddelware(),
        nightscoutMiddleware(),
        appGroupSharingMiddleware(),
        screenLockMiddleware(),
        sensorErrorMiddleware(),
        storeExportMiddleware()
    ]

    if #available(iOS 16.1, *) {
        middlewares.append(widgetCenterMiddleware())
    }

    var connectionInfos: [SensorConnectionInfo] = []

    #if canImport(CoreNFC)
        if NFCTagReaderSession.readingAvailable {
            connectionInfos.append(SensorConnectionInfo(id: DirectConfig.libre2ID, name: LocalizedString("Without transmitter"), connectionCreator: { LibreConnection(subject: $0) }))
            connectionInfos.append(SensorConnectionInfo(id: DirectConfig.bubbleID, name: LocalizedString("Bubble transmitter"), connectionCreator: { BubbleConnection(subject: $0) }))
        } else {
            connectionInfos.append(SensorConnectionInfo(id: DirectConfig.bubbleID, name: LocalizedString("Bubble transmitter"), connectionCreator: { BubbleConnection(subject: $0) }))
        }
    #else
        connectionInfos.append(SensorConnectionInfo(id: DirectConfig.bubbleID, name: LocalizedString("Bubble transmitter"), connectionCreator: { BubbleConnection(subject: $0) }))
    #endif

    if DirectConfig.isDebug {
        connectionInfos.append(SensorConnectionInfo(id: DirectConfig.libreLinkID, name: LocalizedString("LibreLink transmitter"), connectionCreator: { LibreLinkConnection(subject: $0) }))
    }

    middlewares.append(sensorConnectorMiddelware(connectionInfos))

    if DirectConfig.isDebug {
        middlewares.append(debugMiddleware())
    }

    return DirectStore(initialState: AppState(), reducer: directReducer, middlewares: middlewares)
}
