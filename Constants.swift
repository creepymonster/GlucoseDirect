//
//  Infos.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 28.07.21.
//

import Foundation

enum Constants {
    static var WidgetKind: String { "LibreDirectPlaygroundWidget" }
    static var FreeApsXBundleIdentifier: String { "reimarmetzen.FreeAPS" }
    static var AppGroupName: String { "group.\(Constants.FreeApsXBundleIdentifier)" }
    static var AllowedGlucoseChangePerMinute: Double { 0.20 } // in percent, ex: 0.20 = 20%
    static var MinReadableGlucose: Int { 40 }
    static var MaxReadableGlucose: Int { 500 }
    static var ExpiredNotificationInterval: Double { 1 * 60 * 60 } // in seconds
    static var ExpiringNotificationInterval: Double { 24 * 60 * 60 } // in seconds
}
