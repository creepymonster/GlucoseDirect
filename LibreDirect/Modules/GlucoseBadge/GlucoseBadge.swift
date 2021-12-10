//
//  GlucoseBadge.swift
//  LibreDirect
//

import Combine
import Foundation
import UIKit
import UserNotifications

func glucoseBadgeMiddelware() -> Middleware<AppState, AppAction> {
    return glucoseBadgeMiddelware(service: glucoseBadgeService())
}

private func glucoseBadgeMiddelware(service: glucoseBadgeService) -> Middleware<AppState, AppAction> {
    return { store, action, _ in
        switch action {
        case .setGlucoseBadge(enabled: let enabled):
            if !enabled {
                UIApplication.shared.applicationIconBadgeNumber = 0
                service.clearNotifications()
            }
            
        case .addGlucose(glucose: let glucose):
            guard store.state.glucoseBadge else {
                break
            }
            
            service.setGlucoseBadge(glucose: glucose, glucoseUnit: store.state.glucoseUnit)

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - glucoseBadgeService

private class glucoseBadgeService {
    // MARK: Internal

    enum Identifier: String {
        case sensorGlucoseBadge = "libre-direct.notifications.sensor-glucose-badge"
    }

    func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorGlucoseBadge.rawValue])
    }

    func setGlucoseBadge(glucose: Glucose, glucoseUnit: GlucoseUnit) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            Log.info("Glucose info, ensured: \(ensured)")

            guard ensured else {
                return
            }
            
            guard let glucoseValue = glucose.glucoseValue else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none
            notification.interruptionLevel = .passive
            notification.title = String(format: LocalizedString("Blood glucose: %1$@", comment: ""), glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true))
            notification.body = String(
                format: LocalizedString("Your current glucose is %1$@ (%2$@).", comment: ""),
                glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true),
                glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? "?"
            )

            if glucoseUnit == .mgdL {
                notification.badge = glucoseValue as NSNumber
            } else {
                notification.badge = glucoseValue.asMmolL as NSNumber
            }

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseBadge.rawValue, content: notification)
        }
    }
}
