//
//  GlucoseAlert.swift
//  LibreDirect
//

import Combine
import Foundation
import UserNotifications

func glucoseNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return glucoseNotificationMiddelware(service: GlucoseNotificationService())
}

private func glucoseNotificationMiddelware(service: GlucoseNotificationService) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .setGlucoseAlarm(enabled: let enabled):
            if !enabled {
                service.clearNotifications()
            }
            
        case .setAlarmSnoozeUntil(untilDate: let untilDate):
            guard untilDate != nil else {
                break
            }
            
            service.clearNotifications()

        case .addGlucose(glucose: let glucose):
            guard state.glucoseAlarm, glucose.type == .cgm else {
                break
            }

            guard let glucoseValue = glucose.glucoseValue else {
                break
            }

            var isSnoozed = false

            if let snoozeUntil = state.alarmSnoozeUntil, Date() < snoozeUntil {
                AppLog.info("Glucose alert snoozed until \(snoozeUntil.localTime)")
                isSnoozed = true
            }

            if glucoseValue < state.alarmLow {
                if !isSnoozed {
                    AppLog.info("Glucose alert, low: \(glucose.glucoseValue) < \(state.alarmLow)")

                    service.sendLowGlucoseNotification(glucose: glucose, glucoseUnit: state.glucoseUnit)

                    return Just(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(5 * 60).rounded(on: 1, .minute)))
                        .setFailureType(to: AppError.self)
                        .eraseToAnyPublisher()
                }
            } else if glucoseValue > state.alarmHigh {
                if !isSnoozed {
                    AppLog.info("Glucose alert, high: \(glucose.glucoseValue) > \(state.alarmHigh)")

                    service.sendHighGlucoseNotification(glucose: glucose, glucoseUnit: state.glucoseUnit)

                    return Just(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(5 * 60).rounded(on: 1, .minute)))
                        .setFailureType(to: AppError.self)
                        .eraseToAnyPublisher()
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

// MARK: - GlucoseNotificationService

private class GlucoseNotificationService {
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
            AppLog.info("Glucose alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            guard let glucoseValue = glucose.glucoseValue else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.userInfo = self.actions
            notification.sound = NotificationService.AlarmSound

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .critical
            }

            notification.title = LocalizedString("Alert, low blood glucose", comment: "")
            notification.body = String(
                format: LocalizedString("Your glucose %1$@ (%2$@) is dangerously low. With sweetened drinks or dextrose, blood glucose levels can often return to normal."),
                glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true),
                glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?"
            )

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlert.rawValue, content: notification)
        }
    }

    func sendHighGlucoseNotification(glucose: Glucose, glucoseUnit: GlucoseUnit) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            AppLog.info("Glucose alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            guard let glucoseValue = glucose.glucoseValue else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.userInfo = self.actions
            notification.sound = NotificationService.AlarmSound

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .critical
            }

            notification.title = LocalizedString("Alert, high glucose", comment: "")
            notification.body = String(
                format: LocalizedString("Your glucose %1$@ (%2$@) is dangerously high and needs to be treated."),
                glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true),
                glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?"
            )

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlert.rawValue, content: notification)
        }
    }

    // MARK: Private

    private let actions: [AnyHashable: Any] = [
        "action": "snooze"
    ]
}
