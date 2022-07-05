//
//  SensorExpired.swift
//  GlucoseDirect
//

import Combine
import Foundation
import UserNotifications

func expiringNotificationMiddelware() -> Middleware<DirectState, DirectAction> {
    return expiringNotificationMiddelware(service: LazyService<ExpiringNotificationService>(initialization: {
        ExpiringNotificationService()
    }))
}

private func expiringNotificationMiddelware(service: LazyService<ExpiringNotificationService>) -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .setExpiringAlarmSound(sound: let sound):
            if sound == .none {
                service.value.clearAlarm()
            }

        case .setSensorState(sensorAge: let sensorAge, sensorState: _):
            guard state.expiringAlarm else {
                DirectLog.info("Guard: expiringAlarm disabled")
                break
            }

            guard let sensor = state.sensor else {
                DirectLog.info("Guard: state.sensor is nil")
                break
            }

            DirectLog.info("Sensor expiring alert check, age: \(sensorAge)")

            let remainingMinutes = max(0, sensor.lifetime - sensorAge)
            if remainingMinutes == 0 { // expired
                DirectLog.info("Sensor is expired")

                service.value.setSensorExpiredAlarm(ignoreMute: state.ignoreMute, sound: state.expiringAlarmSound)

            } else if remainingMinutes <= (8 * 60 + 1) { // less than 8 hours
                DirectLog.info("Sensor is expiring in less than 8 hours")

                if remainingMinutes.inHours == 0 {
                    service.value.setSensorExpiringAlarm(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ minutes."), remainingMinutes.inMinutes.description), ignoreMute: state.ignoreMute, sound: state.expiringAlarmSound)
                } else {
                    service.value.setSensorExpiringAlarm(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ hours."), remainingMinutes.inHours.description), ignoreMute: state.ignoreMute, sound: state.expiringAlarmSound)
                }

            } else if remainingMinutes <= (24 * 60 + 1) { // less than 24 hours
                DirectLog.info("Sensor is expiring in less than 24 hours")

                service.value.setSensorExpiringAlarm(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ hours."), remainingMinutes.inHours.description), ignoreMute: state.ignoreMute, sound: .none)
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - ExpiringNotificationService

private class ExpiringNotificationService {
    // MARK: Lifecycle

    init() {
        DirectLog.info("Create ExpiringNotificationService")
    }

    // MARK: Internal

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

        nextExpiredAlert = Date().addingTimeInterval(DirectConfig.expiredNotificationInterval)

        DirectNotifications.shared.ensureCanSendNotification { state in
            DirectLog.info("Sensor expired alert, state: \(state)")

            guard state != .none else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none
            notification.interruptionLevel = .timeSensitive

            notification.title = LocalizedString("Alert, sensor expired")
            notification.body = LocalizedString("Your sensor has expired and needs to be replaced as soon as possible")

            DirectNotifications.shared.add(identifier: Identifier.sensorExpiringAlarm.rawValue, content: notification)

            if state == .sound {
                DirectNotifications.shared.playSound(ignoreMute: ignoreMute, sound: sound)
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
        nextExpiredAlert = Date().addingTimeInterval(DirectConfig.expiredNotificationInterval)

        DirectNotifications.shared.ensureCanSendNotification { state in
            DirectLog.info("Sensor expired alert, state: \(state)")

            guard state != .none else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none

            if sound != .none {
                notification.interruptionLevel = .timeSensitive
            } else {
                notification.interruptionLevel = .passive
            }

            notification.title = LocalizedString("Alert, sensor expiring soon")
            notification.body = body

            DirectNotifications.shared.add(identifier: Identifier.sensorExpiringAlarm.rawValue, content: notification)

            if state == .sound && sound != .none {
                DirectNotifications.shared.playSound(ignoreMute: ignoreMute, sound: sound)
            }
        }
    }
}
