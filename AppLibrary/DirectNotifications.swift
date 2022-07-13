//
//  NotificationCenterService.swift
//  GlucoseDirect
//

import AudioToolbox
import AVFoundation
import Foundation
import UIKit
import UserNotifications

// MARK: - DirectNotifications

class DirectNotifications {
    // MARK: Lifecycle

    private init() {
        if let soundURL = FrameworkBundle.main.url(forResource: "mute", withExtension: "aiff"), AudioServicesCreateSystemSoundID(soundURL as CFURL, &muteSoundID) == kAudioServicesNoError {
            var yes: UInt32 = 1
            AudioServicesSetProperty(kAudioServicesPropertyIsUISound, UInt32(MemoryLayout.size(ofValue: muteSoundID)), &muteSoundID, UInt32(MemoryLayout.size(ofValue: yes)), &yes)
        }
    }

    // MARK: Internal

    static let shared = DirectNotifications()

    static var SilentSound: UNNotificationSound {
        UNNotificationSound(named: UNNotificationSoundName(rawValue: "silent.aiff"))
    }

    func isPlaying() -> Bool {
        if let player = player {
            return player.isPlaying
        }

        return false
    }

    func stopSound() {
        guard let player = player else {
            DirectLog.info("Guard: player is nil")
            return
        }

        if player.isPlaying {
            player.stop()
        }
    }

    func getSound(sound: NotificationSound) -> UNNotificationSound {
        UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(sound.rawValue).aiff"))
    }

    func playSound(sound: NotificationSound, ignoreMute: Bool = false) {
        guard sound != .none else {
            return
        }

        checkMute { isMuted in
            if isMuted, !ignoreMute {
                self.playVibration(times: 1)
            } else if sound == .vibration {
                self.playVibration()
            } else {
                self.playSound(ignoreMute: ignoreMute, named: sound.rawValue)
            }
        }
    }

    func remove(identifier: String) {
        let center = UNUserNotificationCenter.current()

        DirectLog.info("NotificationCenter, identifier: \(identifier)")
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func add(identifier: String, content: UNMutableNotificationContent, trigger: UNNotificationTrigger? = nil) {
        remove(identifier: identifier)

        let center = UNUserNotificationCenter.current()
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        DirectLog.info("NotificationCenter, identifier: \(identifier)")
        DirectLog.info("NotificationCenter, content: \(content)")
        center.add(request)
    }

    func ensureCanSendNotification(_ completion: @escaping (_ state: NotificationState) -> Void) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .badge, .criticalAlert, .provisional, .sound]) { granted, _ in
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
    private var muteSoundID: SystemSoundID = 0

    private var isMuted = false
    private var player: AVAudioPlayer?

    private func checkMute(_ completion: @escaping (_ isMuted: Bool) -> Void) {
        muteCheckStart = Date.timeIntervalSinceReferenceDate

        AudioServicesPlaySystemSoundWithCompletion(muteSoundID) { [weak self] in
            if let self = self {
                let elapsed = Date.timeIntervalSinceReferenceDate - self.muteCheckStart
                let isMuted = elapsed < 0.1

                completion(isMuted)
            }
        }
    }

    private func playVibration(times: Int = 5) {
        if times == 0 {
            return
        }

        AudioServicesPlaySystemSoundWithCompletion(1352) {
            self.playVibration(times: times - 1)
        }
    }

    private func playSound(ignoreMute: Bool, named: String) {
        checkMute { isMuted in
            guard !isMuted || ignoreMute else {
                DirectLog.info("Guard: Audio is muted")
                return
            }

            guard let soundURL = FrameworkBundle.main.url(forResource: named, withExtension: "aiff") else {
                DirectLog.info("Guard: FrameworkBundle.main.url(forResource: \(named), withExtension: aiff) is nil")
                return
            }

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                DirectLog.error("NotificationCenter, could not set AVAudioSession category to playback and mixwithOthers, error = \(error.localizedDescription)")
            }

            do {
                let player = try AVAudioPlayer(contentsOf: soundURL)
                // player.volume = 0.2
                player.prepareToPlay()
                player.play()

                self.player = player
            } catch {
                DirectLog.error("NotificationCenter, exception while trying to play sound, error = \(error.localizedDescription)")
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
