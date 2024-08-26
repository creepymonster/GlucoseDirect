//
//  AppConfig.swift
//  GlucoseDirect
//

import Foundation

// MARK: - AppConfig

enum DirectConfig {
    static let appSchemaURL = URL(string: "glucosedirect://")
    static let bubbleID = "bubble"
    static let calibrationsViewTag = 3
    static let crowdinURL = "https://crwd.in/glucose-direct-app"
    static let donateURL = "https://www.paypal.me/creepymonstr"
    static let expiredNotificationInterval: Double = 1 * 60 * 60 // in seconds
    static let facebookURL = "https://www.facebook.com/groups/4747621411996068/"
    static let faqURL = "https://github.com/creepymonster/GlucoseDirect/blob/main/FAQ.md#faq"
    static let githubURL = "https://github.com/creepymonster/GlucoseDirectApp"
    static let lastChartHours = 24
    static let libre2ID = "libre2"
    static let libreLinkID = "librelink"
    static let listsViewTag = 2
    static let maxReadableGlucose = 501
    static let minGlucoseStatisticsDays = 7
    static let minReadableGlucose = 39
    static let overviewViewTag = 1
    static let projectName = "GlucoseDirect"
    static let settingsViewTag = 4
    static let smoothThresholdSeconds: Double = 15 * 60
    static let timegroupRounding = 15
    static let virtualID = "virtual"
    static let widgetName = "\(appName) Widget"
    static var bloodGlucoseInput = true
    static var customCalibration = true
    static var glucoseErrors = false
    static var glucoseStatistics = true
    static let showSmoothedGlucose = true
    static var showInsulinInput = true

    static var appName: String = {
        Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as! String
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

    static var isDebug: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}
