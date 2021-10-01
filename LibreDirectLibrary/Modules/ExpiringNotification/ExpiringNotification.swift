//
//  SensorExpired.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation
import Combine
import UserNotifications

public func expiringNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return expiringNotificationMiddelware(service: expiringNotificationService())
}

func expiringNotificationMiddelware(service: expiringNotificationService) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .setSensorAge(sensorAge: let sensorAge):
            guard let sensor = store.state.sensor else {
                break
            }

            Log.info("Sensor expiring alert check, age: \(sensorAge)")

            let remainingMinutes = max(0, sensor.lifetime - sensorAge)
            if remainingMinutes < 5 { // expired
                Log.info("Sensor expired alert!")

                service.sendSensorExpiredNotification()

            } else if remainingMinutes <= (8 * 60 + 1) { // less than 8 hours
                Log.info("Sensor expiring alert, less than 8 hours")

                if remainingMinutes.inHours == 0 {
                    service.sendSensorExpiringNotification(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ minutes.", comment: ""), remainingMinutes.inMinutes.description), withSound: true)
                } else {
                    service.sendSensorExpiringNotification(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ hours.", comment: ""), remainingMinutes.inHours.description), withSound: true)
                }


            } else if remainingMinutes <= (24 * 60 + 1) { // less than 24 hours
                Log.info("Sensor expiring alert check, less than 24 hours")

                service.sendSensorExpiringNotification(body: String(format: LocalizedString("Your sensor is about to expire. Replace sensor in %1$@ hours.", comment: ""), remainingMinutes.inHours.description))

            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

class expiringNotificationService {
    var nextExpiredAlert: Date? = nil
    var lastExpiringAlert: String = ""

    enum Identifier: String {
        case sensorExpiring = "libre-direct.notifications.sensor-expiring-alert"
    }

    func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorExpiring.rawValue])
    }

    func sendSensorExpiredNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        guard nextExpiredAlert == nil || Date() >= nextExpiredAlert! else {
            return
        }

        nextExpiredAlert = Date().addingTimeInterval(AppConfig.ExpiredNotificationInterval)

        NotificationCenterService.shared.ensureCanSendNotification { ensured in
            Log.info("Sensor expired alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("Alert, sensor expired", comment: "")
            notification.body = LocalizedString("Your sensor has expired and needs to be replaced as soon as possible", comment: "")
            notification.sound = .none

            NotificationCenterService.shared.add(identifier: Identifier.sensorExpiring.rawValue, content: notification)
            NotificationCenterService.shared.playAlarmSound()
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

        NotificationCenterService.shared.ensureCanSendNotification { ensured in
            Log.info("Sensor expired alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("Alert, sensor expiring soon", comment: "")
            notification.body = body
            notification.sound = .none

            NotificationCenterService.shared.add(identifier: Identifier.sensorExpiring.rawValue, content: notification)

            if withSound {
                NotificationCenterService.shared.playExpiringSound()
            }
        }
    }
}
