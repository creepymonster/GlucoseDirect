//
//  NotificationCenterService.swift
//  LibreDirect
//

import AudioToolbox
import AVFoundation
import Foundation
import UIKit
import UserNotifications

// MARK: - NotificationService

class NotificationService {
    // MARK: Lifecycle

    private init() {
        if let soundURL = FrameworkBundle.main.url(forResource: "mute", withExtension: "aiff"), AudioServicesCreateSystemSoundID(soundURL as CFURL, &muteSoundId) == kAudioServicesNoError {
            var yes: UInt32 = 1
            AudioServicesSetProperty(kAudioServicesPropertyIsUISound, UInt32(MemoryLayout.size(ofValue: muteSoundId)), &muteSoundId, UInt32(MemoryLayout.size(ofValue: yes)), &yes)
        }
    }

    // MARK: Internal

    static let shared = NotificationService()

    static let SilentSound: UNNotificationSound = {
        UNNotificationSound(named: UNNotificationSoundName(rawValue: "silent.aiff"))
    }()

    func isPlaying() -> Bool {
        if let player = player {
            return player.isPlaying
        }

        return false
    }

    func stopSound() {
        guard let player = player else {
            AppLog.info("Guard: player is nil")
            return
        }

        if player.isPlaying {
            player.stop()
        }
    }

    func playSound(sound: NotificationSound) {
        playSound(named: sound.rawValue)
    }

    func add(identifier: String, content: UNMutableNotificationContent) {
        let center = UNUserNotificationCenter.current()
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        AppLog.info("NotificationCenter, identifier: \(identifier)")
        AppLog.info("NotificationCenter, content: \(content)")

        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }

    func ensureCanSendNotification(_ completion: @escaping (_ state: NotificationState) -> Void) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                center.getNotificationSettings { settings in
                    if settings.soundSetting == .enabled {
                        completion(.sound)
                    } else {
                        completion(.silent)
                    }
                }

            } else {
                completion(.none)
            }
        }
    }

    // MARK: Private

    private var muteCheckStart: TimeInterval = 0
    private var muteSoundId: SystemSoundID = 0

    private var isMuted = false
    private var player: AVAudioPlayer?

    private func checkMute(_ completion: @escaping (_ isMuted: Bool) -> Void) {
        muteCheckStart = Date.timeIntervalSinceReferenceDate

        AudioServicesPlaySystemSoundWithCompletion(muteSoundId) { [weak self] in
            if let self = self {
                let elapsed = Date.timeIntervalSinceReferenceDate - self.muteCheckStart
                let isMuted = elapsed < 0.1

                completion(isMuted)
            }
        }
    }

    private func playSound(named: String) {
        checkMute { isMuted in
            guard !isMuted else {
                AppLog.info("Guard: Audio is muted")
                return
            }

            guard let soundURL = FrameworkBundle.main.url(forResource: named, withExtension: "aiff") else {
                AppLog.info("Guard: FrameworkBundle.main.url(forResource: \(named), withExtension: aiff) is nil")
                return
            }

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                AppLog.error("NotificationCenter, could not set AVAudioSession category to playback and mixwithOthers, error = \(error.localizedDescription)")
            }

            do {
                let player = try AVAudioPlayer(contentsOf: soundURL)
                player.volume = 0.25
                player.prepareToPlay()
                player.play()

                self.player = player
            } catch {
                AppLog.error("NotificationCenter, exception while trying to play sound, error = \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - NotificationState

enum NotificationState {
    case none
    case silent
    case sound
}

// MARK: - NotificationSound

enum NotificationSound: String, Codable {
    case none
    case alarm
    case expiring
    case negative
    case positive
}
