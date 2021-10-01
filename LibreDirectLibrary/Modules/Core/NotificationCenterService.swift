//
//  NotificationCenterService.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation
import UserNotifications
import UIKit
import AVFoundation

class NotificationCenterService {
    private var player: AVPlayer?
    static let shared = NotificationCenterService()

    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            Log.info("NotificationCenter, error: \(error.localizedDescription)")
        }
    }

    func stopSound() {
        guard let player = player else {
            return
        }

        player.pause()
    }

    func playSilentSound() {
        playSound(named: "silent")
    }

    func playAlarmSound() {
        playSound(named: "alarm")
    }

    func playExpiringSound() {
        playSound(named: "expiring")
    }

    func playNegativeSound() {
        playSound(named: "negative")
    }

    func playPositiveSound() {
        playSound(named: "positive")
    }

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

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    private func playSound(named: String) {
        guard let soundURL = FrameworkBundle.main.url(forResource: named, withExtension: "aiff") else { return }

        let player = AVPlayer.init(url: soundURL)
        player.play()

        self.player = player
    }
}

