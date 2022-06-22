//
//  GlucoseType.swift
//  GlucoseDirect
//

import Foundation

enum GlucoseType: Equatable, Codable {
    case cgm
    case bgm
    case faulty(SensorReadingQuality)

    // MARK: Internal

    var localizedString: String {
        switch self {
        case .cgm:
            return LocalizedString("CGM")
        case .bgm:
            return LocalizedString("BGM")
        case .faulty(quality: let quality):
            return LocalizedString("Failure: \(quality.description)")
        }
    }
}
