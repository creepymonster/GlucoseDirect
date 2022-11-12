//
//  AppConfig.swift
//  GlucoseDirect
//

import Foundation

// MARK: - AppConfig

enum DirectConfig {
    static var appSchemaURL = URL(string: "glucosedirect://")

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

    static var bubbleID = "bubble"
    static var calibrationsViewTag = 3
    static var crowdinURL = "https://crwd.in/glucose-direct-app"
    static var donateURL = "https://www.paypal.me/reimarmetzen"
    static var expiredNotificationInterval: Double = 1 * 60 * 60 // in seconds
    static var facebookURL = "https://www.facebook.com/groups/4747621411996068/"
    static var faqURL = "https://github.com/creepymonster/GlucoseDirectApp"
    static var githubURL = "https://github.com/creepymonster/GlucoseDirectApp"
    static var libre2ID = "libre2"
    static var libreLinkID = "librelink"
    static var listsViewTag = 2
    static var maxReadableGlucose = 501
    static var minReadableGlucose = 39
    static var overviewViewTag = 1
    static var projectName = "GlucoseDirect"
    static var settingsViewTag = 4
    static var virtualID = "virtual"
    static var widgetName = "\(appName) Widget"
    static var minGlucoseStatisticsDays = 7
    static var timegroupRounding = 15
    static var lastChartHours = 24
    static var smoothThresholdSeconds: Double = 15 * 60

    static var smoothSensorGlucoseValues: Bool {
        true
    }

    static var drawRawGlucoseValues: Bool {
        if isDebug {
            return true
        } else {
            return false
        }
    }

    static var customCalibration: Bool {
        if isDebug {
            return true
        } else {
            return false
        }
    }

    static var isDebug: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}
