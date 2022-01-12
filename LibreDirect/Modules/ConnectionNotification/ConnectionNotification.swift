//
//  SensorConnectionLostAlert.swift
//  LibreDirect
//

import Combine
import Foundation
import UserNotifications

func connectionNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return connectionNotificationMiddelware(service: {
        ConnectionNotificationService()
    }())
}

private func connectionNotificationMiddelware(service: ConnectionNotificationService) -> Middleware<AppState, AppAction> {
    return { state, action, lastState in
        switch action {
        case .setConnectionAlarmSound(sound: let sound):
            if sound == .none {
                service.clearAlarm()
            }

        case .setConnectionError(errorMessage: _, errorTimestamp: _, errorIsCritical: let errorIsCritical):
            guard state.connectionAlarm else {
                AppLog.info("Guard: connectionAlarm disabled")
                break
            }

            service.setSensorConnectionLostAlarm(errorIsCritical: errorIsCritical, ignoreMute: state.ignoreMute, sound: state.connectionAlarmSound)

        case .setConnectionState(connectionState: let connectionState):
            guard state.connectionAlarm else {
                AppLog.info("Guard: connectionAlarm disabled")
                break
            }

            if lastState.connectionState == .connected, connectionState == .disconnected {
                service.setSensorConnectionLostAlarm(errorIsCritical: false, ignoreMute: state.ignoreMute, sound: state.connectionAlarmSound)

            } else if lastState.connectionState != .connected, connectionState == .connected {
                service.clearAlarm()
            }

        case .addMissedReading:
            guard state.connectionAlarm else {
                AppLog.info("Guard: connectionAlarm disabled")
                break
            }

            if state.missedReadings % 5 == 0 {
                service.setSensorMissedReadingsAlarm(missedReadings: state.missedReadings, ignoreMute: state.ignoreMute, sound: state.connectionAlarmSound)
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - ConnectionNotificationService

private class ConnectionNotificationService {
    enum Identifier: String {
        case sensorConnectionAlarm = "libre-direct.notifications.sensor-connection-alarm"
    }

    func clearAlarm() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorConnectionAlarm.rawValue])
    }

    func setSensorConnectionLostAlarm(errorIsCritical: Bool, ignoreMute: Bool, sound: NotificationSound) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Sensor connection lost alert, state: \(state)")

            guard state != .none else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = NotificationService.SilentSound
            notification.title = LocalizedString("Alert, sensor connection lost", comment: "")

            if errorIsCritical {
                if #available(iOS 15.0, *) {
                    notification.interruptionLevel = .critical
                }

                notification.body = LocalizedString("The sensor cannot be connected and rejects all connection attempts. This problem makes it necessary to re-pair the sensor.", comment: "")
            } else {
                if #available(iOS 15.0, *) {
                    notification.interruptionLevel = .passive
                }

                notification.body = LocalizedString("The connection with the sensor has been interrupted. Normally this happens when the sensor is out of range or its transmission power is impaired.", comment: "")
            }

            NotificationService.shared.add(identifier: Identifier.sensorConnectionAlarm.rawValue, content: notification)

            if state == .sound && errorIsCritical {
                NotificationService.shared.playSound(ignoreMute: ignoreMute, sound: sound)
            }
        }
    }

    func setSensorConnectionRestoredAlarm() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Sensor connection lost alert, state: \(state)")

            guard state != .none else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = NotificationService.SilentSound

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }

            notification.title = LocalizedString("OK, sensor connection established", comment: "")
            notification.body = LocalizedString("The connection to the sensor has been successfully established and glucose data is received.", comment: "")

            NotificationService.shared.add(identifier: Identifier.sensorConnectionAlarm.rawValue, content: notification)
        }
    }

    func setSensorMissedReadingsAlarm(missedReadings: Int, ignoreMute: Bool, sound: NotificationSound) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { state in
            AppLog.info("Sensor missed readings, state: \(state)")

            guard state != .none else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = NotificationService.SilentSound

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .timeSensitive
            }

            notification.title = String(format: LocalizedString("Warning, sensor missed %1$@ readings", comment: ""), missedReadings.description)
            notification.body = LocalizedString("The connection to the sensor seems to exist, but no values are received. Faulty sensor data may be the cause.", comment: "")

            NotificationService.shared.add(identifier: Identifier.sensorConnectionAlarm.rawValue, content: notification)

            if state == .sound {
                NotificationService.shared.playSound(ignoreMute: ignoreMute, sound: sound)
            }
        }
    }
}
