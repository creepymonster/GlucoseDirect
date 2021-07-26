//
//  SensorGlucoseAlert.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 19.07.21.
//

import Foundation
import Combine
import UserNotifications

func sensorGlucoseAlertMiddelware(service: SensorGlucoseAlertService) -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .setSensorReading(readingUpdate: let readingUpdate):
            var isSnoozed = false

            if let snoozeUntil = state.alarmSnoozeUntil, Date() < snoozeUntil {
                Log.info("Glucose alert snoozed until \(snoozeUntil.localTime)")
                isSnoozed = true
            }

            if readingUpdate.lastGlucose.glucoseFiltered < state.alarmLow {
                if !isSnoozed {
                    Log.info("Glucose alert, low: \(readingUpdate.lastGlucose.glucoseFiltered) < \(state.alarmLow)")

                    service.sendLowGlucoseNotification()
                    return Just(AppAction.setAlarmSnoozeUntil(value: Date().addingTimeInterval(5 * 60).rounded(on: 1, .minute))).eraseToAnyPublisher()
                }
            } else if readingUpdate.lastGlucose.glucoseFiltered > state.alarmHigh {
                if !isSnoozed {
                    Log.info("Glucose alert, high: \(readingUpdate.lastGlucose.glucoseFiltered) > \(state.alarmHigh)")

                    service.sendHighGlucoseNotification()
                    return Just(AppAction.setAlarmSnoozeUntil(value: Date().addingTimeInterval(5 * 60).rounded(on: 1, .minute))).eraseToAnyPublisher()
                }
            } else {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications() // For removing all delivered notification
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests() // For removing all pending notifications which are not delivered yet but scheduled.
                
                return Just(AppAction.setAlarmSnoozeUntil(value: nil)).eraseToAnyPublisher()
            }

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}

class SensorGlucoseAlertService: NotificationCenterService {
    enum Identifier: String {
        case sensorGlucoseAlert = "libre-direct.notifications.sensor-glucose-alert"
    }

    func sendLowGlucoseNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        ensureCanSendNotification { ensured in
            Log.info("Glucose alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = "Notification Title: Sensor glucose low alert"
            notification.body = "Notification Body: Sensor glucose low"
            notification.sound = .defaultCritical

            self.add(identifier: Identifier.sensorGlucoseAlert.rawValue, content: notification)
        }
    }

    func sendHighGlucoseNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        ensureCanSendNotification { ensured in
            Log.info("Glucose alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = "Notification Title: Sensor glucose high alert"
            notification.body = "Notification Body: Sensor glucose high"
            notification.sound = .defaultCritical

            self.add(identifier: Identifier.sensorGlucoseAlert.rawValue, content: notification)
        }
    }
}
