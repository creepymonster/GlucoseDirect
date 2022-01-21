//
//  SensorExpired.swift
//  LibreDirect
//

import Combine
import Foundation
import UserNotifications

func expiringNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return expiringNotificationMiddelware(service: {
        ExpiringNotificationService()
    }())
}

private func expiringNotificationMiddelware(service: ExpiringNotificationService) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .setExpiringAlarmSound(sound: let sound):
            if sound == .none {
                service.clearAlarm()
            }

        case .setSensorState(sensorAge: let sensorAge, sensorState: _):
            guard state.expiringAlarm else {
                AppLog.info("Guard: expiringAlarm disabled")
                break
            }

            guard let sensor = state.sensor else {
                AppLog.info("Guard: state.sensor is nil")
                break
            }

            AppLog.info("Sensor expiring alert check, age: \(sensorAge)")

            let remainingMinutes = max(0, sensor.lifetime - sensorAge)
            if remainingMinutes == 0 { // expired
                AppLog.info("Sensor is expired")

                service.setSensorExpiredAlarm(ignoreMute: state.ignoreMute, sound: state.expiringAlarmSound)

            } else if remainingMinutes <= (8 * 60 + 1) { // less than 8 hours
                AppLog.info("Sensor is expiring in less than 8 hours")

                if remainingMinutes.inHours == 0 {
                    service.setSensorExpiringAlarm(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ minutes."), remainingMinutes.inMinutes.description), ignoreMute: state.ignoreMute, sound: state.expiringAlarmSound)
                } else {
                    service.setSensorExpiringAlarm(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ hours."), remainingMinutes.inHours.description), ignoreMute: state.ignoreMute, sound: state.expiringAlarmSound)
                }

            } else if remainingMinutes <= (24 * 60 + 1) { // less than 24 hours
                AppLog.info("Sensor is expiring in less than 24 hours")

                service.setSensorExpiringAlarm(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ hours."), remainingMinutes.inHours.description), ignoreMute: state.ignoreMute, sound: .none)
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
        case sensorExpiringAlarm = "libre-direct.notifications.sensor-expiring-alarm"
    }

    var nextExpiredAlert: Date?
    var lastExpiringAlert: String = ""

    func clearAlarm() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorExpiringAlarm.rawValue])
    }

    func setSensorExpiredAlarm(ignoreMute: Bool, sound: NotificationSound) {
        guard nextExpiredAlert == nil || Date() >= nextExpiredAlert! else {
            return
        }

        nextExpiredAlert = Date().addingTimeInterval(AppConfig.expiredNotificationInterval)

        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Sensor expired alert, state: \(state)")

            guard state != .none else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = NotificationService.SilentSound

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .critical
            }

            notification.title = LocalizedString("Alert, sensor expired")
            notification.body = LocalizedString("Your sensor has expired and needs to be replaced as soon as possible")

            NotificationService.shared.add(identifier: Identifier.sensorExpiringAlarm.rawValue, content: notification)

            if state == .sound {
                NotificationService.shared.playSound(ignoreMute: ignoreMute, sound: sound)
            }
        }
    }

    func setSensorExpiringAlarm(body: String, ignoreMute: Bool, sound: NotificationSound) {
        guard lastExpiringAlert != body else {
            return
        }

        guard nextExpiredAlert == nil || Date() >= nextExpiredAlert! else {
            return
        }

        lastExpiringAlert = body
        nextExpiredAlert = Date().addingTimeInterval(AppConfig.expiredNotificationInterval)

        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Sensor expired alert, state: \(state)")

            guard state != .none else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = NotificationService.SilentSound

            if sound != .none {
                if #available(iOS 15.0, *) {
                    notification.interruptionLevel = .timeSensitive
                }
            } else {
                if #available(iOS 15.0, *) {
                    notification.interruptionLevel = .passive
                }
            }

            notification.title = LocalizedString("Alert, sensor expiring soon")
            notification.body = body

            NotificationService.shared.add(identifier: Identifier.sensorExpiringAlarm.rawValue, content: notification)

            if state == .sound && sound != .none {
                NotificationService.shared.playSound(ignoreMute: ignoreMute, sound: sound)
            }
        }
    }
}
