//
//  SensorExpired.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
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

            guard ageUpdate.sensorAge >= sensor.lifetime else {
                break
            }

            service.sendSensorExpiredNotification()
        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

class SensorExpiredAlertService: NotificationCenterService {
    enum Identifier: String {
        case sensorExpired = "libre-direct.notifications.sensor-expired-alert"
    }

    func sendSensorExpiredNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        ensureCanSendNotification { ensured in
            Log.info("Sensor expired alert, ensured: \(ensured)")
            
            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = "Notification Title: Sensor expired"
            notification.body = "Notification Body: Please replace your old sensor as soon as possible"
            notification.sound = .defaultCritical

            self.add(identifier: Identifier.sensorExpired.rawValue, content: notification)
        }
    }
}
