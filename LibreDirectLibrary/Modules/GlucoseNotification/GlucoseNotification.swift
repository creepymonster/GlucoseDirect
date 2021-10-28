//
//  SensorGlucoseAlert.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 19.07.21.
//

import Foundation
import Combine
import UserNotifications

public func glucoseNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return glucoseNotificationMiddelware(service: glucoseNotificationService())
}

func glucoseNotificationMiddelware(service: glucoseNotificationService) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .setSensorReading(glucose: let glucose):
            var isSnoozed = false

            if let snoozeUntil = store.state.alarmSnoozeUntil, Date() < snoozeUntil {
                Log.info("Glucose alert snoozed until \(snoozeUntil.localTime)")
                isSnoozed = true
            }

            if glucose.glucoseFiltered < store.state.alarmLow {
                if !isSnoozed {
                    Log.info("Glucose alert, low: \(glucose.glucoseFiltered) < \(store.state.alarmLow)")

                    service.sendLowGlucoseNotification(glucose: "\(glucose.glucoseFiltered.asGlucose(unit: store.state.glucoseUnit)) \(store.state.glucoseUnit.description)")

                    DispatchQueue.main.async {
                        store.dispatch(.setAlarmSnoozeUntil(value: Date().addingTimeInterval(5 * 60).rounded(on: 1, .minute)))
                    }
                }
            } else if glucose.glucoseFiltered > store.state.alarmHigh {
                if !isSnoozed {
                    Log.info("Glucose alert, high: \(glucose.glucoseFiltered) > \(store.state.alarmHigh)")

                    service.sendHighGlucoseNotification(glucose: "\(glucose.glucoseFiltered.asGlucose(unit: store.state.glucoseUnit)) \(store.state.glucoseUnit.description)")

                    DispatchQueue.main.async {
                        store.dispatch(.setAlarmSnoozeUntil(value: Date().addingTimeInterval(5 * 60).rounded(on: 1, .minute)))
                    }
                }
            } else {
                service.clearNotifications()
            }

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}

class glucoseNotificationService {
    enum Identifier: String {
        case sensorGlucoseAlert = "libre-direct.notifications.sensor-glucose-alert"
    }

    func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorGlucoseAlert.rawValue])
    }

    func sendLowGlucoseNotification(glucose: String) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            Log.info("Glucose alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none
            notification.title = LocalizedString("Alert, low blood glucose", comment: "")
            notification.body = String(format: LocalizedString("Your glucose %1$@ is dangerously low. With sweetened drinks or dextrose, blood glucose levels can often return to normal.", comment: ""), glucose)
            
            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlert.rawValue, content: notification)
            NotificationService.shared.playAlarmSound()
        }
    }

    func sendHighGlucoseNotification(glucose: String) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            Log.info("Glucose alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none
            notification.title = LocalizedString("Alert, high glucose", comment: "")
            notification.body = String(format: LocalizedString("Your glucose %1$@ is dangerously high and needs to be treated.", comment: ""), glucose)
            
            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlert.rawValue, content: notification)
            NotificationService.shared.playAlarmSound()
        }
    }
}
