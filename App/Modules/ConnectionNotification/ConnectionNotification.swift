//
//  SensorConnectionLostAlert.swift
//  GlucoseDirect
//

import Combine
import Foundation
import UserNotifications
import WidgetKit

func connectionNotificationMiddelware() -> Middleware<DirectState, DirectAction> {
    return connectionNotificationMiddelware(service: LazyService<ConnectionNotificationService>(initialization: {
        ConnectionNotificationService()
    }))
}

private func connectionNotificationMiddelware(service: LazyService<ConnectionNotificationService>) -> Middleware<DirectState, DirectAction> {
    return { state, action, lastState in
        switch action {
        case .startup:
            guard state.hasConnectionAlarm else {
                DirectLog.info("Guard: connectionAlarm disabled")
                break
            }

            service.value.scheduleSensorConnectionLostAlarm(sound: state.connectionAlarmSound)

        case .setConnectionState(connectionState: let connectionState):
            guard state.hasConnectionAlarm else {
                DirectLog.info("Guard: connectionAlarm disabled")
                break
            }

            DirectLog.info("Set connection state, current: \(connectionState), last: \(lastState.connectionState)")

            if connectionState == .connected {
                service.value.clearAlarm()
            } else if connectionState == .disconnected, lastState.connectionState == .connected {
                service.value.scheduleSensorConnectionLostAlarm(sound: state.connectionAlarmSound)
            }

        case .setConnectionAlarmSound(sound: let sound):
            if sound == .none {
                service.value.clearAlarm()
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - ConnectionNotificationService

private class ConnectionNotificationService {
    // MARK: Lifecycle

    init() {
        DirectLog.info("Create ConnectionNotificationService")
    }

    // MARK: Internal

    enum Identifier: String {
        case sensorConnectionAlarm = "libre-direct.notifications.sensor-connection-alarm"
    }

    func clearAlarm() {
        DirectLog.info("Clear alarm")
        DirectNotifications.shared.removeNotification(identifier: Identifier.sensorConnectionAlarm.rawValue)
    }

    func scheduleSensorConnectionLostAlarm(sound: NotificationSound) {
        DirectLog.info("Schedule sensor connection lost alarm")

        DirectNotifications.shared.ensureCanSendNotification { state in
            DirectLog.info("Schedule sensor connection lost alarm, state: \(state)")

            guard state != .none else {
                return
            }

            let notification = UNMutableNotificationContent()

            if sound != .none, state == .sound {
                notification.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(sound.rawValue).aiff"))
            } else {
                notification.sound = .none
            }

            notification.title = LocalizedString("Alert, sensor connection lost")
            notification.interruptionLevel = .timeSensitive
            notification.body = LocalizedString("The connection with the sensor has been interrupted. Normally this happens when the sensor is out of range or its transmission power is impaired.")

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: true)
            DirectNotifications.shared.addNotification(identifier: Identifier.sensorConnectionAlarm.rawValue, content: notification, trigger: trigger)
        }
    }
}
