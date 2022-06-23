//
//  NotificationSound.swift
//  GlucoseDirect
//

import Foundation

enum NotificationSound: String, Codable, CaseIterable {
    case positive
    case ping
    case negative
    case lowBattery = "low-battery"
    case lose
    case longAlarm = "long-alarm"
    case jump
    case hit
    case highlight
    case future
    case failure
    case expiring
    case collectPoint = "collect-point"
    case coinInsert = "coin-insert"
    case coinChime = "coin-chime"
    case climbRope = "climb-rope"
    case chiptone
    case buzzBeep = "buzz-beep"
    case alarm
    case achievement
    case vibration
    case none

    // MARK: Internal

    var description: String {
        rawValue
    }

    var localizedString: String {
        rawValue
    }
}
