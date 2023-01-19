//
//  DirectHelper.swift
//  GlucoseDirect
//

import Foundation
import SwiftUI

class DirectHelper {
    static var warning: String? {
        if let sensor = UserDefaults.shared.sensor, sensor.state != .ready {
            return sensor.state.localizedDescription
        }
        
        guard let connectionStateRawValue = UserDefaults.shared.sharedSensorConnectionState else {
            return nil
        }
        
        let connectionState = SensorConnectionState(rawValue: connectionStateRawValue)!

        if connectionState != .connected {
            return connectionState.localizedDescription
        }
        
        return nil
    }

    static func isAlarm(glucose: any Glucose) -> Bool {
        if glucose.glucoseValue < UserDefaults.shared.alarmLow || glucose.glucoseValue > UserDefaults.shared.alarmHigh {
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
}

// TODO:
