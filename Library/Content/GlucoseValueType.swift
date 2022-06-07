//
//  GlucoseValueType.swift
//  GlucoseDirect
//

import Foundation

enum GlucoseValueType: String, Codable {
    case cgm = "CGM"
    case bgm = "BGM"
    case none = "None"
}