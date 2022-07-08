//
//  GlucoseType.swift
//  GlucoseDirect
//

import Foundation

enum GlucoseType: String, Codable {
    case cgm
    case bgm
    case faulty

    // MARK: Internal

    var description: String {
        rawValue
    }

    var localizedString: String {
        LocalizedString(rawValue)
    }
}
