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
            if let snoozeUntil = state.alarmSnoozeUntil, Date() < snoozeUntil {
                Log.info("Glucose alert snoozed until \(snoozeUntil.localTime)")
                
                break
            }
            
            if readingUpdate.lastGlucose.glucoseFiltered < state.alarmLow {
                Log.info("Glucose alert, low: \(readingUpdate.lastGlucose.glucoseFiltered) < \(state.alarmLow)")
                
                service.sendLowGlucoseNotification()
            } else if readingUpdate.lastGlucose.glucoseFiltered > state.alarmHigh {
                Log.info("Glucose alert, high: \(readingUpdate.lastGlucose.glucoseFiltered) > \(state.alarmHigh)")
                
                service.sendHighGlucoseNotification()
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
