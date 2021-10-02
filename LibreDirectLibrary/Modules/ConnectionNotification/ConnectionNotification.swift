//
//  SensorConnectionLostAlert.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 29.07.21. 
//

import Foundation
import Combine
import UserNotifications

public func connectionNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return connectionNotificationMiddelware(service: connectionNotificationService())
}

func connectionNotificationMiddelware(service: connectionNotificationService) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .setSensorConnection(connectionState: let connectionState):
            Log.info("Sensor connection lost alert check: \(connectionState)")

            if lastState.connectionState == .connected && connectionState == .disconnected {
                service.sendSensorConnectionLostNotification()
            } else if lastState.connectionState != .connected && connectionState == .connected {
                //service.sendSensorConnectionRestoredNotification()
                service.clearNotifications()
            }

        case .setSensorMissedReadings:
            Log.info("Sensor connection available, but missed readings")

            if store.state.missedReadings % 5 == 0 {
                service.sendSensorMissedReadingsNotification(missedReadings: store.state.missedReadings)
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

class connectionNotificationService {
    enum Identifier: String {
        case sensorConnectionAlert = "libre-direct.notifications.sensor-connection-alert"
    }

    func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorConnectionAlert.rawValue])
    }

    func sendSensorConnectionLostNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            Log.info("Sensor connection lLost alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("Alert, sensor connection lost", comment: "")
            notification.body = LocalizedString("The connection with the sensor has been lost. Normally this happens when the sensor is outside the possible range.", comment: "")
            notification.sound = .none

            NotificationService.shared.add(identifier: Identifier.sensorConnectionAlert.rawValue, content: notification)
        }
    }

    func sendSensorConnectionRestoredNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            Log.info("Sensor connection lLost alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("OK, sensor connection established", comment: "")
            notification.body = LocalizedString("The connection to the sensor has been successfully established and glucose data is received.", comment: "")
            notification.sound = .none

            NotificationService.shared.add(identifier: Identifier.sensorConnectionAlert.rawValue, content: notification)
        }
    }

    func sendSensorMissedReadingsNotification(missedReadings: Int) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            Log.info("Sensor missed readings, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = String(format: LocalizedString("Warning, sensor missed %1$@ readings", comment: ""), missedReadings.description)
            notification.body = LocalizedString("The connection to the sensor seems to exist, but no values are received. Faulty sensor data may be the cause.", comment: "")
            notification.sound = .none

            NotificationService.shared.add(identifier: Identifier.sensorConnectionAlert.rawValue, content: notification)
            NotificationService.shared.playNegativeSound()
        }
    }
}
