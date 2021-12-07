//
//  GlucoseAlert.swift
//  LibreDirect
//

import Combine
import Foundation
import UserNotifications

func glucoseNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return glucoseNotificationMiddelware(service: glucoseNotificationService())
}

private func glucoseNotificationMiddelware(service: glucoseNotificationService) -> Middleware<AppState, AppAction> {
    return { store, action, _ in
        switch action {
        case .setGlucoseAlarm(enabled: let enabled):
            if !enabled {
                service.clearNotifications()
            }

        case .addGlucose(glucose: let glucose):
            guard store.state.glucoseAlarm, glucose.type == .cgm else {
                break
            }

            var isSnoozed = false

            if let snoozeUntil = store.state.alarmSnoozeUntil, Date() < snoozeUntil {
                Log.info("Glucose alert snoozed until \(snoozeUntil.localTime)")
                isSnoozed = true
            }

            if glucose.glucoseValue < store.state.alarmLow {
                if !isSnoozed {
                    Log.info("Glucose alert, low: \(glucose.glucoseValue) < \(store.state.alarmLow)")

                    service.sendLowGlucoseNotification(glucose: glucose, glucoseUnit: store.state.glucoseUnit)

                    DispatchQueue.main.async {
                        store.dispatch(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(5 * 60).rounded(on: 1, .minute)))
                    }
                }
            } else if glucose.glucoseValue > store.state.alarmHigh {
                if !isSnoozed {
                    Log.info("Glucose alert, high: \(glucose.glucoseValue) > \(store.state.alarmHigh)")

                    service.sendHighGlucoseNotification(glucose: glucose, glucoseUnit: store.state.glucoseUnit)

                    DispatchQueue.main.async {
                        store.dispatch(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(5 * 60).rounded(on: 1, .minute)))
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

// MARK: - glucoseNotificationService

private class glucoseNotificationService {
    // MARK: Internal

    enum Identifier: String {
        case sensorGlucoseAlert = "libre-direct.notifications.sensor-glucose-alert"
    }

    func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorGlucoseAlert.rawValue])
    }

    func sendLowGlucoseNotification(glucose: Glucose, glucoseUnit: GlucoseUnit) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            Log.info("Glucose alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.userInfo = self.actions
            notification.sound = .none
            notification.title = LocalizedString("Alert, low blood glucose", comment: "")
            notification.body = String(format: LocalizedString("Your glucose %1$@ (%2$@) is dangerously low. With sweetened drinks or dextrose, blood glucose levels can often return to normal.", comment: ""), glucose.glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true), glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?")

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlert.rawValue, content: notification)
            NotificationService.shared.playAlarmSound()
        }
    }

    func sendHighGlucoseNotification(glucose: Glucose, glucoseUnit: GlucoseUnit) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            Log.info("Glucose alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.userInfo = self.actions
            notification.sound = .none
            notification.title = LocalizedString("Alert, high glucose", comment: "")
            notification.body = String(format: LocalizedString("Your glucose %1$@ (%2$@) is dangerously high and needs to be treated.", comment: ""), glucose.glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true), glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?")

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlert.rawValue, content: notification)
            NotificationService.shared.playAlarmSound()
        }
    }

    // MARK: Private

    private let actions: [AnyHashable: Any] = [
        "action": "snooze"
    ]
}
