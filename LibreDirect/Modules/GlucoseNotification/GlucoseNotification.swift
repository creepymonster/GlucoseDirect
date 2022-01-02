//
//  GlucoseAlert.swift
//  LibreDirect
//

import Combine
import Foundation
import UIKit
import UserNotifications

func glucoseNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return glucoseNotificationMiddelware(service: {
        GlucoseNotificationService()
    }())
}

private func glucoseNotificationMiddelware(service: GlucoseNotificationService) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .setGlucoseAlarm(enabled: let enabled):
            if !enabled {
                service.clearAlarm()
            }

        case .setGlucoseBadge(enabled: let enabled):
            if !enabled {
                service.clearBadge()
            }

        case .setAlarmSnoozeUntil(untilDate: let untilDate, autosnooze: let autosnooze):
            guard untilDate != nil else {
                AppLog.info("Guard: untilDate is nil")
                break
            }

            if !autosnooze {
                service.clearAlarm()
            }

        case .setGlucoseUnit(unit: let unit):
            guard let glucose = state.currentGlucose else {
                break
            }

            service.setGlucoseBadge(glucose: glucose, glucoseUnit: unit)

        case .addGlucoseValues(glucoseValues: let glucoseValues):
            guard let glucose = glucoseValues.last else {
                AppLog.info("Guard: glucoseValues.last is nil")
                break
            }

            guard glucose.type == .cgm else {
                AppLog.info("Guard: glucose.type is not .cgm")
                break
            }

            guard let glucoseValue = glucose.glucoseValue else {
                AppLog.info("Guard: glucose.glucoseValue is nil")
                break
            }

            var isSnoozed = false
            if let snoozeUntil = state.alarmSnoozeUntil, Date() < snoozeUntil {
                isSnoozed = true
            }

            AppLog.info("isSnoozed: \(isSnoozed)")

            if state.glucoseAlarm, glucoseValue < state.alarmLow, !isSnoozed {
                AppLog.info("Glucose alert, low: \(glucose.glucoseValue) < \(state.alarmLow)")

                service.clearBadge()
                service.setLowGlucoseAlarm(glucose: glucose, glucoseUnit: state.glucoseUnit)

                return Just(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(5 * 60).toRounded(on: 1, .minute), autosnooze: true))
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()

            } else if state.glucoseAlarm, glucoseValue > state.alarmHigh, !isSnoozed {
                AppLog.info("Glucose alert, high: \(glucose.glucoseValue) > \(state.alarmHigh)")

                service.clearBadge()
                service.setHighGlucoseAlarm(glucose: glucose, glucoseUnit: state.glucoseUnit)

                return Just(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(5 * 60).toRounded(on: 1, .minute), autosnooze: true))
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()

            } else if state.glucoseBadge {
                service.setGlucoseBadge(glucose: glucose, glucoseUnit: state.glucoseUnit)
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
        case sensorGlucoseBadge = "libre-direct.notifications.sensor-glucose-badge"
        case sensorGlucoseAlarm = "libre-direct.notifications.sensor-glucose-alarm"
    }

    func clearAlarm() {
        NotificationService.shared.stopSound()
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorGlucoseAlarm.rawValue])
    }

    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorGlucoseBadge.rawValue])
    }

    func setGlucoseBadge(glucose: Glucose, glucoseUnit: GlucoseUnit) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Glucose info, state: \(state)")

            guard state != .none else {
                return
            }

            guard let glucoseValue = glucose.glucoseValue else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = NotificationService.SilentSound

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }

            if glucoseUnit == .mgdL {
                notification.badge = glucoseValue as NSNumber
            } else {
                notification.badge = glucoseValue.asRoundedMmolL as NSNumber
            }

            notification.title = String(format: LocalizedString("Blood glucose: %1$@", comment: ""), glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true))
            notification.body = String(
                format: LocalizedString("Your current glucose is %1$@ (%2$@).", comment: ""),
                glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true),
                glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?"
            )

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseBadge.rawValue, content: notification)
        }
    }

    func setLowGlucoseAlarm(glucose: Glucose, glucoseUnit: GlucoseUnit) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Glucose alert, state: \(state)")

            guard state != .none else {
                return
            }

            guard let glucoseValue = glucose.glucoseValue else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = NotificationService.SilentSound
            notification.userInfo = self.actions

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .critical
            }

            if glucoseUnit == .mgdL {
                notification.badge = glucoseValue as NSNumber
            } else {
                notification.badge = glucoseValue.asRoundedMmolL as NSNumber
            }

            notification.title = LocalizedString("Alert, low blood glucose", comment: "")
            notification.body = String(
                format: LocalizedString("Your glucose %1$@ (%2$@) is dangerously low. With sweetened drinks or dextrose, blood glucose levels can often return to normal."),
                glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true),
                glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?"
            )

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlarm.rawValue, content: notification)

            if state == .sound {
                NotificationService.shared.playAlarmSound()
            }
        }
    }

    func setHighGlucoseAlarm(glucose: Glucose, glucoseUnit: GlucoseUnit) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Glucose alert, state: \(state)")

            guard state != .none else {
                return
            }

            guard let glucoseValue = glucose.glucoseValue else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = NotificationService.SilentSound
            notification.userInfo = self.actions

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .critical
            }

            if glucoseUnit == .mgdL {
                notification.badge = glucoseValue as NSNumber
            } else {
                notification.badge = glucoseValue.asRoundedMmolL as NSNumber
            }

            notification.title = LocalizedString("Alert, high glucose", comment: "")
            notification.body = String(
                format: LocalizedString("Your glucose %1$@ (%2$@) is dangerously high and needs to be treated."),
                glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true),
                glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?"
            )

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlarm.rawValue, content: notification)

            if state == .sound {
                NotificationService.shared.playAlarmSound()
            }
        }
    }

    // MARK: Private

    private let actions: [AnyHashable: Any] = [
        "action": "snooze"
    ]
}

private extension Int {
    var asRoundedMmolL: Double {
        let value = Double(self) * GlucoseUnit.exchangeRate
        let divisor = pow(10.0, Double(1))

        return round(value * divisor) / divisor
    }
}
