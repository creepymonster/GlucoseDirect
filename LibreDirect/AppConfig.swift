//
//  AppConfig.swift
//  LibreDirect
//

import Foundation

// MARK: - AppConfig

enum AppConfig {
    static var appSchemaUrl = URL(string: "libredirect://")
    static var githubUrl = "https://github.com/creepymonster/GlucoseDirectApp"
    static var faqUrl = "https://github.com/creepymonster/GlucoseDirectApp"
    static var crowdinUrl = "https://crwd.in/glucose-direct-app"
    static var facebookUrl = "https://www.facebook.com/groups/4747621411996068/"
    static var donateUrl = "https://www.paypal.me/reimarmetzen"

    static var projectName = "GlucoseDirect"

    static var appName: String = {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as! String
    }()

    static var appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    }()
    
    static var appBuild: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as! String
    }()

    static var appAuthor: String? = {
        Bundle.main.infoDictionary?["AppAuthor"] as? String
    }()

    static var appSupportMail: String? = {
        Bundle.main.infoDictionary?["AppSupportMail"] as? String
    }()

    static var internalHttpServerPort: UInt16 = 1979
    static var minReadableGlucose: Int { 40 }
    static var maxReadableGlucose: Int { 500 }
    static var expiredNotificationInterval: Double { 1 * 60 * 60 } // in seconds
    static var numberOfGlucoseValues: Int { 48 * 60 } // every minute a value
}
