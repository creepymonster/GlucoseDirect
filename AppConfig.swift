//
//  AppConfig.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 28.07.21.
//

import Foundation

enum AppConfig {
    static var WidgetKind: String { "LibreDirectWidget" }
    static var FreeApsXBundleIdentifier: String { "reimarmetzen.FreeAPS" }
    static var AppGroupName: String { "group.\(AppConfig.FreeApsXBundleIdentifier)" }
    static var AllowedGlucoseChange: Double { 8 } // in mg/dl/min.
    static var MinReadableGlucose: Int { 40 }
    static var MaxReadableGlucose: Int { 500 }
    static var ExpiredNotificationInterval: Double { 1 * 60 * 60 } // in seconds
    static var NumberOfGlucoseValues: Int? { 24 * 60 } // every minute a value
}
 
