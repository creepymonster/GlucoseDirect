//
//  AppConfig.swift
//  GlucoseDirect
//

import Foundation

// MARK: - AppConfig

enum DirectConfig {
    static var appSchemaURL = URL(string: "glucosedirect://")
    static var githubURL = "https://github.com/creepymonster/GlucoseDirectApp"
    static var faqURL = "https://github.com/creepymonster/GlucoseDirectApp"
    static var crowdinURL = "https://crwd.in/glucose-direct-app"
    static var facebookURL = "https://www.facebook.com/groups/4747621411996068/"
    static var donateURL = "https://www.paypal.me/reimarmetzen"

    static var projectName = "GlucoseDirect"

    static var appName: String = {
        Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as! String
    }()
    
    static var widgetName: String = {
       "\(appName) Widget"
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

    static var minReadableGlucose: Int { 39 }
    static var maxReadableGlucose: Int { 501 }
    static var expiredNotificationInterval: Double { 1 * 60 * 60 } // in seconds
    static var numberOfGlucoseValues: Int { 48 * 60 } // every minute a value
}
