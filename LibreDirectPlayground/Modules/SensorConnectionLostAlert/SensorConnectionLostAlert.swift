//
//  SensorConnectionLostAlert.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 29.07.21.
//

import Foundation
import Combine
import UserNotifications

func sensorConnectionLostAlertMiddelware(service: SensorConnectionLostAlertService) -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .setSensorConnection(connectionUpdate: let connectionUpdate):
            Log.info("Sensor connection lost alert check: \(connectionUpdate.connectionState)")
                       
            if connectionUpdate.connectionState == .disconnected {
                Log.info("Sensor connection lost alert, send")
                service.sendSensorConnectionLostNotification()

            } else if connectionUpdate.connectionState == .connected {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications() // For removing all delivered notification
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests() // For removing all pending notifications which are not delivered yet but scheduled.
                
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

class SensorConnectionLostAlertService: NotificationCenterService {
    enum Identifier: String {
        case sensorConnectionLost = "libre-direct.notifications.sensor-connection-lost"
    }

    func sendSensorConnectionLostNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        ensureCanSendNotification { ensured in
            Log.info("Sensor connection lLost alert, ensured: \(ensured)")
            
            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("Alert, sensor connection lost", comment: "")
            notification.body = LocalizedString("The connection with the sensor has been lost. Normally this happens when the sensor is outside the possible range.", comment: "")
            notification.sound = .defaultCritical

            self.add(identifier: Identifier.sensorConnectionLost.rawValue, content: notification)
        }
    }
}
