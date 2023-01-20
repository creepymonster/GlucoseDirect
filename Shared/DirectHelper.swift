//
//  DirectHelper.swift
//  GlucoseDirect
//

import Foundation
import SwiftUI

enum DirectHelper {
    static func isAlarm(glucose: any Glucose) -> Bool {
        isAlarm(glucose: glucose, alarmLow: UserDefaults.standard.alarmLow, alarmHigh: UserDefaults.standard.alarmHigh)
    }
    
    static func isAlarm(glucose: any Glucose, alarmLow: Int, alarmHigh: Int) -> Bool {
        if glucose.glucoseValue < alarmLow || glucose.glucoseValue > alarmHigh {
            return true
        }
        
        return false
    }
    
    static func getGlucoseColor(glucose: any Glucose) -> Color {
        if isAlarm(glucose: glucose) {
            return Color.ui.red
        }
        
        return Color.primary
    }
    
    static func getWarning(sensorState: SensorState?, connectionState: SensorConnectionState?) -> String? {
        if let sensorState, sensorState != .ready {
            return sensorState.localizedDescription
        }
        
        if let connectionState, connectionState != .connected {
            return connectionState.localizedDescription
        }
        
        return nil
    }
}
