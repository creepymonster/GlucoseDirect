//
//  SensorConnectionLostAlert.swift
//  LibreDirect
//

import Combine
import Foundation
import UserNotifications

func connectionNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return connectionNotificationMiddelware(service: connectionNotificationService())
}

private func connectionNotificationMiddelware(service: connectionNotificationService) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .setConnectionAlarm(enabled: let enabled):
            if !enabled {
                service.clearNotifications()
            }
            
        case .setConnectionState(connectionState: let connectionState):
            guard store.state.connectionAlarm else {
                break
            }
            
            Log.info("Sensor connection lost alert check: \(connectionState)")

            if lastState.connectionState == .connected, connectionState == .disconnected {
                service.sendSensorConnectionLostNotification()
            } else if lastState.connectionState != .connected, connectionState == .connected {
                // service.sendSensorConnectionRestoredNotification()
                service.clearNotifications()
            }

        case .addMissedReading:
            guard store.state.connectionAlarm else {
                break
            }
            
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

// MARK: - connectionNotificationService

private class connectionNotificationService {
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
            notification.sound = .none
            notification.title = LocalizedString("Alert, sensor connection lost", comment: "")
            notification.body = LocalizedString("The connection with the sensor has been lost. Normally this happens when the sensor is outside the possible range.", comment: "")

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }

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
            notification.sound = .none
            notification.title = LocalizedString("OK, sensor connection established", comment: "")
            notification.body = LocalizedString("The connection to the sensor has been successfully established and glucose data is received.", comment: "")

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }

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
            notification.sound = .none
            notification.title = String(format: LocalizedString("Warning, sensor missed %1$@ readings", comment: ""), missedReadings.description)
            notification.body = LocalizedString("The connection to the sensor seems to exist, but no values are received. Faulty sensor data may be the cause.", comment: "")

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .timeSensitive
            }

            NotificationService.shared.add(identifier: Identifier.sensorConnectionAlert.rawValue, content: notification)
            NotificationService.shared.playNegativeSound()
        }
    }
}
