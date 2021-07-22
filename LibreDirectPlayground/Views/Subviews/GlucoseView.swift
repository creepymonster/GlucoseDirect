//
//  SensorGlucoseView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct GlucoseView: View {
    var glucose: SensorGlucose?
    var alarmLow: Int?
    var alarmHigh: Int?

    var body: some View {
        if let glucose = glucose {
            VStack {
                Text("\(glucose.glucoseFiltered.description)").font(.system(size: 60)).foregroundColor(getForegroundColor())
                
                HStack {
                    Text("\(glucose.trend.description)")
                    Text("\(getMinuteChange())/min.")
                    Text("\(glucose.timeStamp.localTime)")
                }
            }
        } else {
            VStack {
                Text("...").font(.system(size: 60)).foregroundColor(getForegroundColor())
            }
        }
    }
    
    func getMinuteChange() -> String {
        if let glucose = glucose {
            if glucose.minuteChange > 0 {
                return "+\(glucose.minuteChange)"
            } else if glucose.minuteChange < 0 {
                return "\(glucose.minuteChange)"
            } else {
                return "0"
            }
        }
        
        return ""
    }

    func getForegroundColor() -> Color {
        if let glucose = glucose {
            if let alarmLow = alarmLow, glucose.glucoseFiltered < alarmLow {
                return Color.accentColor
            }
            
            if let alarmHigh = alarmHigh, glucose.glucoseFiltered > alarmHigh {
                return Color.accentColor
            }
        }

        return Color.primary
    }
}

struct GlucoseView_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseView(glucose: SensorGlucose(id: 1, timeStamp: Date(), glucose: 60, minuteChange: 2), alarmLow: 70, alarmHigh: 180)
        GlucoseView(glucose: SensorGlucose(id: 1, timeStamp: Date(), glucose: 100, minuteChange: -2), alarmLow: 70, alarmHigh: 180)
        GlucoseView(glucose: SensorGlucose(id: 1, timeStamp: Date(), glucose: 190, minuteChange: 0), alarmLow: 70, alarmHigh: 180)
        GlucoseView(glucose: nil, alarmLow: 70, alarmHigh: 180)
    }
}
