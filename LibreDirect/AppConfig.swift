//
//  AppConfig.swift
//  LibreDirect
//

import Foundation

// MARK: - AppConfig

enum AppConfig {
    static var AppSchemaUrl = URL(string: "libredirect://")
    static var RepoUrl = "https://github.com/creepymonster/GlucoseDirectApp"

    static var appName: String = {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as! String
    }()

    static var appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    }()

    static var MinReadableGlucose: Int { 40 }
    static var MaxReadableGlucose: Int { 500 }
    static var ExpiredNotificationInterval: Double { 1 * 60 * 60 } // in seconds
    static var NumberOfGlucoseValues: Int? { 24 * 60 } // every minute a value
}
