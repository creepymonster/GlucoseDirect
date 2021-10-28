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
            service.setGlucoseBadge(glucose: glucose, glucoseUnit: store.state.glucoseUnit)

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
    
    var formatter: NumberFormatter {
        get {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.positivePrefix = "+"
            formatter.maximumFractionDigits = 1
            
            return formatter
        }
    }

    func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorGlucoseBadge.rawValue])
    }
        
    func setGlucoseBadge(glucose: SensorGlucose, glucoseUnit: GlucoseUnit) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            Log.info("Glucose info, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none
            notification.title = String(format: LocalizedString("Blood glucose: %1$@", comment: ""), glucose.glucoseFiltered.asGlucose(unit: glucoseUnit, withUnit: true))
            notification.body = String(format: LocalizedString("Your current glucose is %1$@ (%2$@).", comment: ""), glucose.glucoseFiltered.asGlucose(unit: glucoseUnit, withUnit: true), self.getMinuteChange(glucose: glucose, glucoseUnit: glucoseUnit))
            
            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }
            
            if glucoseUnit == .mgdL {
                notification.badge = glucose.glucoseFiltered as NSNumber
            } else {
                notification.badge = glucose.glucoseFiltered.asMmolL as NSNumber
            }

            NotificationService.shared.add(identifier: Identifier.sensorGlucoseBadge.rawValue, content: notification)
        }
    }
    
    private func getMinuteChange(glucose: SensorGlucose, glucoseUnit: GlucoseUnit) -> String {
        var formattedMinuteChange = ""
        
        if let minuteChange = glucose.minuteChange {
            if glucoseUnit == .mgdL {
                formattedMinuteChange = formatter.string(from: minuteChange as NSNumber)!
            } else {
                formattedMinuteChange = formatter.string(from: minuteChange.asMmolL as NSNumber)!
            }
        } else {
            formattedMinuteChange = "?"
        }
        
        return String(format: LocalizedString("%1$@/min.", comment: ""), formattedMinuteChange)
    }
}
