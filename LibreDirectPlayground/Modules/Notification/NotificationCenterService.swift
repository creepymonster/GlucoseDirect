//
//  NotificationService.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import UserNotifications

class NotificationCenterService {
    func add(identifier: String, content: UNMutableNotificationContent) {
        let center = UNUserNotificationCenter.current()
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }

    func ensureCanSendNotification(_ completion: @escaping (_ canSend: Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if #available (iOSApplicationExtension 12.0, *) {
                guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                    completion(false)

                    return
                }
            } else {
                guard settings.authorizationStatus == .authorized else {
                    completion(false)

                    return
                }
            }

            completion(true)
        }
    }
}
