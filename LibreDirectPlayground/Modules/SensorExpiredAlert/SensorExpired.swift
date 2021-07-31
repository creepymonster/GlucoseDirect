//
//  SensorExpired.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 06.07.21.
//

import Foundation
import Combine
import UserNotifications

func sensorExpiredAlertMiddelware(service: SensorExpiredAlertService) -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .setSensorAge(ageUpdate: let ageUpdate):
            guard let sensor = state.sensor else {
                break
            }
            
            Log.info("Sensor expired alert check, age: \(ageUpdate.sensorAge), lifetime: \(sensor.lifetime)")

            let alreadyExpired = !(sensor.lifetime - ageUpdate.sensorAge > 0)
            if alreadyExpired {
                Log.info("Sensor expired alert, send")
                
                service.sendSensorExpiredNotificationIfNeeded()
                break
            }
            
            let remainingDays: Int = (sensor.lifetime - ageUpdate.sensorAge) / (24 * 60)
            if remainingDays <= 3 {
                Log.info("Sensor expiring alert, send")
                
                service.sendSensorExpiringNotificationIfNeeded(remainingDays: remainingDays)
                break
            }
        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

class SensorExpiredAlertService: NotificationCenterService {
    var nextExpiredAlert: Date? = nil
    var nextExpiringAlert: Date? = nil
    
    enum Identifier: String {
        case sensorExpired = "libre-direct.notifications.sensor-expired-alert"
        case sensorExpiring = "libre-direct.notifications.sensor-expiring-alert"
    }

    func sendSensorExpiredNotificationIfNeeded() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
        
        guard nextExpiredAlert == nil || nextExpiredAlert! < Date() else {
            return
        }
        
        nextExpiredAlert = Date().addingTimeInterval(Constants.ExpiredNotificationInterval)

        ensureCanSendNotification { ensured in
            Log.info("Sensor expired alert, ensured: \(ensured)")
            
            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("Alert, sensor expired alert", comment: "")
            notification.body = LocalizedString("Your sensor has expired and needs to be replaced as soon as possible", comment: "")
            notification.sound = .defaultCritical

            self.add(identifier: Identifier.sensorExpired.rawValue, content: notification)
        }
    }
    
    func sendSensorExpiringNotificationIfNeeded(remainingDays: Int = 0) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
        
        guard nextExpiringAlert == nil || nextExpiringAlert! < Date() else {
            return
        }
        
        nextExpiringAlert = Date().addingTimeInterval(Constants.ExpiringNotificationInterval)

        ensureCanSendNotification { ensured in
            Log.info("Sensor expired alert, ensured: \(ensured)")
            
            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("Alert, sensor expiring alert", comment: "")
            notification.body = String(format: LocalizedString("Your sensor is about to expire and will need to be replaced in about %1$@ days.", comment: ""), remainingDays.description)
            notification.sound = .defaultCritical

            self.add(identifier: Identifier.sensorExpiring.rawValue, content: notification)
        }
    }
}
