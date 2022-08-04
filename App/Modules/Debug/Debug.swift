//
//  Debug.swift
//  GlucoseDirectApp
//

import Combine
import Foundation
import UserNotifications

func debugMiddleware() -> Middleware<DirectState, DirectAction> {
    return debugMiddleware(service: LazyService<DebugService>(initialization: {
        DebugService()
    }))
}

private func debugMiddleware(service: LazyService<DebugService>) -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .debugAlarm:
            service.value.debugAlarm(sound: state.expiringAlarmSound, ignoreMute: state.ignoreMute)

        case .debugNotification:
            service.value.debugNotification(sound: state.expiringAlarmSound, ignoreMute: state.ignoreMute)

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - DebugService

private class DebugService {
    // MARK: Lifecycle

    init() {
        DirectLog.info("Create DebugService")
    }

    // MARK: Internal

    enum Identifier: String {
        case debugAlarm = "libre-direct.notifications.debug-alarm"
    }

    func clearAlarm() {
        DirectNotifications.shared.removeNotification(identifier: Identifier.debugAlarm.rawValue)
    }

    func debugAlarm(sound: NotificationSound, ignoreMute: Bool) {
        DirectNotifications.shared.ensureCanSendNotification { state in
            guard state == .sound else {
                return
            }

            DirectNotifications.shared.playSound(sound: sound, ignoreMute: ignoreMute)
        }
    }

    func debugNotification(sound: NotificationSound, ignoreMute: Bool) {
        DirectNotifications.shared.ensureCanSendNotification { state in
            let notification = UNMutableNotificationContent()

            if sound != .none, state == .sound {
                notification.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(sound.rawValue).aiff"))
            } else {
                notification.sound = .none
            }

            notification.interruptionLevel = .timeSensitive
            notification.title = LocalizedString("Test notification")

            DirectNotifications.shared.addNotification(identifier: Identifier.debugAlarm.rawValue, content: notification)
        }
    }
}
