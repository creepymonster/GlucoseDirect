//
//  SensorGlucoseBadge.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 24.07.21.
//

import Foundation
import Combine
import UserNotifications
import UIKit

public func glucoseBadgeMiddelware() -> Middleware<AppState, AppAction> {
    return glucoseBadgeMiddelware(service: glucoseBadgeService())
}

func glucoseBadgeMiddelware(service: glucoseBadgeService) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .setSensorReading(glucose: let glucose):
            service.setGlucoseBadge(glucose: glucose.glucoseFiltered, glucoseUnit: store.state.glucoseUnit)

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}

class glucoseBadgeService {
    enum Identifier: String {
        case sensorGlucoseBadge = "libre-direct.notifications.sensor-glucose-badge"
    }

    func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorGlucoseBadge.rawValue])
    }
    
    func setGlucoseBadge(glucose: Int, glucoseUnit: GlucoseUnit) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            Log.info("Glucose info, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none
            notification.title = String(format: LocalizedString("Info, current glucose is %1$@", comment: ""), glucose.asGlucose(unit: glucoseUnit))
            notification.body = String(format: LocalizedString("Your current glucose is %1$@.", comment: ""), glucose.asGlucose(unit: glucoseUnit))
            
            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }
            
            if glucoseUnit == .mgdL {
                notification.badge = glucose as NSNumber
            } else {
                notification.badge = glucose.asMmolL as NSNumber
            }

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseBadge.rawValue, content: notification)
        }
    }
}
