//
//  GlucoseAlert.swift
//  LibreDirect
//

import Combine
import Foundation
import UIKit
import UserNotifications

func glucoseNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return glucoseNotificationMiddelware(service: LazyService<GlucoseNotificationService>(initialization: {
        GlucoseNotificationService()
    }))
}

private func glucoseNotificationMiddelware(service: LazyService<GlucoseNotificationService>) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .setHighGlucoseAlarmSound(sound: let sound):
            if sound == .none {
                service.value.clear()
            }

        case .setLowGlucoseAlarmSound(sound: let sound):
            if sound == .none {
                service.value.clear()
            }

        case .setGlucoseBadge(enabled: let enabled):
            if !enabled {
                service.value.clear()
            }

        case .setGlucoseUnit(unit: let unit):
            guard let glucose = state.currentGlucose else {
                break
            }

            service.value.setGlucoseBadge(glucose: glucose, glucoseUnit: unit)

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

            if state.lowGlucoseAlarm, glucoseValue < state.alarmLow {
                AppLog.info("Glucose alert, low: \(glucose.glucoseValue) < \(state.alarmLow)")

                service.value.setLowGlucoseAlarm(glucose: glucose, glucoseUnit: state.glucoseUnit, ignoreMute: state.ignoreMute, sound: isSnoozed ? .none : state.lowGlucoseAlarmSound)

                if !isSnoozed {
                    return Just(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(5 * 60).toRounded(on: 1, .minute), autosnooze: true))
                        .setFailureType(to: AppError.self)
                        .eraseToAnyPublisher()
                }

            } else if state.highGlucoseAlarm, glucoseValue > state.alarmHigh {
                AppLog.info("Glucose alert, high: \(glucose.glucoseValue) > \(state.alarmHigh)")

                service.value.setHighGlucoseAlarm(glucose: glucose, glucoseUnit: state.glucoseUnit, ignoreMute: state.ignoreMute, sound: isSnoozed ? .none : state.highGlucoseAlarmSound)

                if !isSnoozed {
                    return Just(.setAlarmSnoozeUntil(untilDate: Date().addingTimeInterval(5 * 60).toRounded(on: 1, .minute), autosnooze: true))
                        .setFailureType(to: AppError.self)
                        .eraseToAnyPublisher()
                }

            } else if state.glucoseBadge {
                service.value.setGlucoseBadge(glucose: glucose, glucoseUnit: state.glucoseUnit)
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - GlucoseNotificationService

private class GlucoseNotificationService {
    // MARK: Lifecycle

    init() {
        AppLog.info("Create GlucoseNotificationService")
    }

    // MARK: Internal

    enum Identifier: String {
        case sensorGlucoseAlarm = "libre-direct.notifications.sensor-glucose-alarm"
    }

    func clear() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorGlucoseAlarm.rawValue])
    }

    func setGlucoseBadge(glucose: Glucose, glucoseUnit: GlucoseUnit) {
        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Glucose info, state: \(state)")

            guard state != .none else {
                return
            }

            guard let glucoseValue = glucose.glucoseValue else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none
            notification.interruptionLevel = .passive

            if glucoseUnit == .mgdL {
                notification.badge = glucoseValue as NSNumber
            } else {
                notification.badge = glucoseValue.asRoundedMmolL as NSNumber
            }

            notification.title = String(format: LocalizedString("Blood glucose: %1$@"), glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true))
            notification.body = String(format: LocalizedString("Your current glucose is %1$@ (%2$@)."),
                                       glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true),
                                       glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?"
            )

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlarm.rawValue, content: notification)
        }
    }

    func setLowGlucoseAlarm(glucose: Glucose, glucoseUnit: GlucoseUnit, ignoreMute: Bool, sound: NotificationSound) {
        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Glucose alert, state: \(state)")

            guard state != .none else {
                return
            }

            guard let glucoseValue = glucose.glucoseValue else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none
            notification.userInfo = self.actions
            notification.interruptionLevel = sound == .none ? .passive : .timeSensitive

            if glucoseUnit == .mgdL {
                notification.badge = glucoseValue as NSNumber
            } else {
                notification.badge = glucoseValue.asRoundedMmolL as NSNumber
            }

            notification.title = LocalizedString("Alert, low blood glucose")
            notification.body = String(format: LocalizedString("Your glucose %1$@ (%2$@) is dangerously low. With sweetened drinks or dextrose, blood glucose levels can often return to normal."),
                                       glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true),
                                       glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?"
            )

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlarm.rawValue, content: notification)

            if state == .sound {
                NotificationService.shared.playSound(ignoreMute: ignoreMute, sound: sound)
            }
        }
    }

    func setHighGlucoseAlarm(glucose: Glucose, glucoseUnit: GlucoseUnit, ignoreMute: Bool, sound: NotificationSound) {
        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Glucose alert, state: \(state)")

            guard state != .none else {
                return
            }

            guard let glucoseValue = glucose.glucoseValue else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none
            notification.userInfo = self.actions
            notification.interruptionLevel = sound == .none ? .passive : .timeSensitive

            if glucoseUnit == .mgdL {
                notification.badge = glucoseValue as NSNumber
            } else {
                notification.badge = glucoseValue.asRoundedMmolL as NSNumber
            }

            notification.title = LocalizedString("Alert, high glucose")
            notification.body = String(format: LocalizedString("Your glucose %1$@ (%2$@) is dangerously high and needs to be treated."),
                                       glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true),
                                       glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?"
            )

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseAlarm.rawValue, content: notification)

            if state == .sound {
                NotificationService.shared.playSound(ignoreMute: ignoreMute, sound: sound)
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
