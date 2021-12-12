//
//  SensorExpired.swift
//  LibreDirect
//

import Combine
import Foundation
import UserNotifications

func expiringNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return expiringNotificationMiddelware(service: ExpiringNotificationService())
}

private func expiringNotificationMiddelware(service: ExpiringNotificationService) -> Middleware<AppState, AppAction> {
    return { store, action, _ in
        switch action {
        case .setExpiringAlarm(enabled: let enabled):
            if !enabled {
                service.clearNotifications()
            }

        case .setSensorState(sensorAge: let sensorAge, sensorState: _):
            guard store.state.expiringAlarm else {
                break
            }

            guard let sensor = store.state.sensor else {
                break
            }

            AppLog.info("Sensor expiring alert check, age: \(sensorAge)")

            let remainingMinutes = max(0, sensor.lifetime - sensorAge)
            if remainingMinutes == 0 { // expired
                AppLog.info("Sensor expired alert!")

                service.sendSensorExpiredNotification()

            } else if remainingMinutes <= (8 * 60 + 1) { // less than 8 hours
                AppLog.info("Sensor expiring alert, less than 8 hours")

                if remainingMinutes.inHours == 0 {
                    service.sendSensorExpiringNotification(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ minutes.", comment: ""), remainingMinutes.inMinutes.description), withSound: true)
                } else {
                    service.sendSensorExpiringNotification(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ hours.", comment: ""), remainingMinutes.inHours.description), withSound: true)
                }

            } else if remainingMinutes <= (24 * 60 + 1) { // less than 24 hours
                AppLog.info("Sensor expiring alert check, less than 24 hours")

                service.sendSensorExpiringNotification(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ hours.", comment: ""), remainingMinutes.inHours.description))
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - ExpiringNotificationService

private class ExpiringNotificationService {
    enum Identifier: String {
        case sensorExpiring = "libre-direct.notifications.sensor-expiring-alert"
    }

    var nextExpiredAlert: Date?
    var lastExpiringAlert: String = ""

    func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorExpiring.rawValue])
    }

    func sendSensorExpiredNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        guard nextExpiredAlert == nil || Date() >= nextExpiredAlert! else {
            return
        }

        nextExpiredAlert = Date().addingTimeInterval(AppConfig.ExpiredNotificationInterval)

        NotificationService.shared.ensureCanSendNotification { ensured in
            AppLog.info("Sensor expired alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = NotificationService.AlarmSound
            notification.interruptionLevel = .critical
            notification.title = LocalizedString("Alert, sensor expired", comment: "")
            notification.body = LocalizedString("Your sensor has expired and needs to be replaced as soon as possible", comment: "")

            NotificationService.shared.add(identifier: Identifier.sensorExpiring.rawValue, content: notification)
        }
    }

    func sendSensorExpiringNotification(body: String, withSound: Bool = false) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        guard lastExpiringAlert != body else {
            return
        }

        guard nextExpiredAlert == nil || Date() >= nextExpiredAlert! else {
            return
        }

        lastExpiringAlert = body
        nextExpiredAlert = Date().addingTimeInterval(AppConfig.ExpiredNotificationInterval)

        NotificationService.shared.ensureCanSendNotification { ensured in
            AppLog.info("Sensor expired alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            if withSound {
                notification.sound = NotificationService.ExpiringSound
                notification.interruptionLevel = .timeSensitive
            } else {
                notification.sound = .none
                notification.interruptionLevel = .passive
            }
            notification.title = LocalizedString("Alert, sensor expiring soon", comment: "")
            notification.body = body

            NotificationService.shared.add(identifier: Identifier.sensorExpiring.rawValue, content: notification)
        }
    }
}
