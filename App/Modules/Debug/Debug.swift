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
            service.value.debugAlarm(sound: state.expiringAlarmSound)

        case .debugNotification:
            service.value.debugNotification(sound: state.expiringAlarmSound)

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

    func debugAlarm(sound: NotificationSound) {
        DirectNotifications.shared.ensureCanSendNotification { state in
            guard state == .sound else {
                return
            }

            DirectNotifications.shared.playSound(sound: sound)
        }
    }

    func debugNotification(sound: NotificationSound) {
        DirectNotifications.shared.ensureCanSendNotification { state in
            guard state != .none else {
                return
            }

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
