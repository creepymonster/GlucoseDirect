//
//  SensorGlucoseAlert.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 19.07.21.
//

import Foundation
import Combine
import UserNotifications

func sensorGlucoseAlertMiddelware(service: SensorGlucoseAlertNotificationService) -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .setSensorReading(readingUpdate: let readingUpdate):
            if let snoozeUntil = state.alarmSnoozeUntil, Date() < snoozeUntil {
                Log.info("Snoozed until \(snoozeUntil.localTime)")
                break
            }

            if readingUpdate.lastGlucose.glucoseFiltered <= state.alarmLow {
                service.sendLowGlucoseNotification()
            } else if readingUpdate.lastGlucose.glucoseFiltered >= state.alarmHigh {
                service.sendHighGlucoseNotification()
            }

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}

class SensorGlucoseAlertNotificationService: NotificationCenterService {
    enum Identifier: String {
        case sensorGlucoseAlert = "libre-direct.notifications.sensorGlucoseAlert"
    }

    func sendLowGlucoseNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        ensureCanSendNotification { ensured in
            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = "Notification Title: Sensor glucose low alert"
            notification.body = "Notification Body: Sensor glucose low"
            notification.sound = .default

            self.add(identifier: Identifier.sensorGlucoseAlert.rawValue, content: notification)
        }
    }

    func sendHighGlucoseNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        ensureCanSendNotification { ensured in
            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = "Notification Title: Sensor glucose high alert"
            notification.body = "Notification Body: Sensor glucose high"
            notification.sound = .default

            self.add(identifier: Identifier.sensorGlucoseAlert.rawValue, content: notification)
        }
    }
}
