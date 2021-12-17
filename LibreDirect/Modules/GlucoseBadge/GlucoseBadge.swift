//
//  GlucoseBadge.swift
//  LibreDirect
//

import Combine
import Foundation
import UIKit
import UserNotifications

func glucoseBadgeMiddelware() -> Middleware<AppState, AppAction> {
    return glucoseBadgeMiddelware(service: GlucoseBadgeService())
}

private func glucoseBadgeMiddelware(service: GlucoseBadgeService) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .setGlucoseBadge(enabled: let enabled):
            if !enabled {
                service.clearNotifications()
            }

        case .setGlucoseUnit(unit: let unit):
            guard let glucose = state.currentGlucose else {
                break
            }

            service.setGlucoseBadge(glucose: glucose, glucoseUnit: unit)

        case .addGlucose(glucose: let glucose):
            guard state.glucoseBadge else {
                break
            }

            service.setGlucoseBadge(glucose: glucose, glucoseUnit: state.glucoseUnit)

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - GlucoseBadgeService

private class GlucoseBadgeService {
    enum Identifier: String {
        case sensorGlucoseBadge = "libre-direct.notifications.sensor-glucose-badge"
    }

    func clearNotifications() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorGlucoseBadge.rawValue])
    }

    func setGlucoseBadge(glucose: Glucose, glucoseUnit: GlucoseUnit) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            AppLog.info("Glucose info, ensured: \(ensured)")

            guard ensured else {
                return
            }

            guard let glucoseValue = glucose.glucoseValue else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }

            notification.title = String(format: LocalizedString("Blood glucose: %1$@", comment: ""), glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true))
            notification.body = String(
                format: LocalizedString("Your current glucose is %1$@ (%2$@).", comment: ""),
                glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true),
                glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?"
            )

            if glucoseUnit == .mgdL {
                notification.badge = glucoseValue as NSNumber
            } else {
                notification.badge = glucoseValue.asRoundedMmolL as NSNumber
            }

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseBadge.rawValue, content: notification)
        }
    }
}

private extension Int {
    var asRoundedMmolL: Double {
        let value = Double(self) * GlucoseUnit.exchangeRate
        let divisor = pow(10.0, Double(1))

        return round(value * divisor) / divisor
    }
}
