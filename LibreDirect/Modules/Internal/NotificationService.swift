//
//  NotificationCenterService.swift
//  LibreDirect
//

import AVFoundation
import Foundation
import UIKit
import UserNotifications

class NotificationService {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = NotificationService()

    static let SilentSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "silent.aiff"))
    static let AlarmSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "alarm.aiff"))
    static let ExpiringSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "expiring.aiff"))
    static let NegativeSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "negative.aiff"))
    static let PositiveSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "positive.aiff"))

    func add(identifier: String, content: UNMutableNotificationContent) {
        let center = UNUserNotificationCenter.current()
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        Log.info("NotificationCenter, identifier: \(identifier)")
        Log.info("NotificationCenter, content: \(content)")

        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }

    func ensureCanSendNotification(_ completion: @escaping (_ canSend: Bool) -> Void) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
