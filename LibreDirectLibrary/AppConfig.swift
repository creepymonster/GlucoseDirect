//
//  AppConfig.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 28.07.21.
//

import Foundation

public enum AppConfig {
    public static var FreeApsXBundleIdentifier: String { "reimarmetzen.FreeAPS" }
    public static var AppGroupName: String { "group.\(AppConfig.FreeApsXBundleIdentifier)" }
    public static var AllowedGlucoseChange: Double { 8 } // in mg/dl/min.
    public static var MinReadableGlucose: Int { 40 }
    public static var MaxReadableGlucose: Int { 500 }
    public static var ExpiredNotificationInterval: Double { 1 * 60 * 60 } // in seconds
    public static var NumberOfGlucoseValues: Int? { 24 * 60 } // every minute a value
}

