//
//  GlucoseView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI
import LibreDirectLibrary

struct GlucoseView: View {
    var glucose: SensorGlucose?
    var glucoseUnit: GlucoseUnit?
    var alarmLow: Int?
    var alarmHigh: Int?
    
    var formatter: NumberFormatter {
        get {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.positivePrefix = "+"
            formatter.maximumFractionDigits = 1
            
            return formatter
        }
    }

    var minuteChange: String {
        get {
            if let glucose = glucose, let minuteChange = glucose.minuteChange {
                return formatter.string(from: minuteChange as NSNumber)!
            }

            return ""
        }
    }

    var glucoseForegroundColor: Color {
        get {
            if let glucose = glucose {
                if let alarmLow = alarmLow, glucose.glucoseFiltered < alarmLow {
                    return Color.red
                }

                if let alarmHigh = alarmHigh, glucose.glucoseFiltered > alarmHigh {
                    return Color.red
                }
            }

            return Color.primary
        }
    }

    var body: some View {
        if let glucose = glucose, let glucoseUnit = glucoseUnit {
            VStack {
                Text(glucose.glucoseFiltered.asGlucose(unit: glucoseUnit)).font(.system(size: 96)).foregroundColor(glucoseForegroundColor)

                if let _ = glucose.minuteChange {
                    HStack {
                        Text(glucose.trend.description)
                        Text(String(format: LocalizedString("%1$@/min.", comment: ""), minuteChange))
                    }
                    .font(.footnote)
                    .padding(.bottom, 5)
                }

                Text(glucose.timeStamp.localTime)
            }
        }
    }
}

struct GlucoseView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            GlucoseView(glucose: SensorGlucose(id: 1, timeStamp: Date(), glucose: 60, minuteChange: 2), glucoseUnit: .mgdL, alarmLow: 70, alarmHigh: 180).preferredColorScheme($0)
            GlucoseView(glucose: SensorGlucose(id: 1, timeStamp: Date(), glucose: 100, minuteChange: -2), glucoseUnit: .mgdL, alarmLow: 70, alarmHigh: 180).preferredColorScheme($0)
            GlucoseView(glucose: SensorGlucose(id: 1, timeStamp: Date(), glucose: 190, minuteChange: 0), glucoseUnit: .mgdL, alarmLow: 70, alarmHigh: 180).preferredColorScheme($0)
            GlucoseView(glucose: SensorGlucose(id: 1, timeStamp: Date(), glucose: 60, minuteChange: 2), glucoseUnit: .mmolL, alarmLow: 70, alarmHigh: 180).preferredColorScheme($0)
            GlucoseView(glucose: SensorGlucose(id: 1, timeStamp: Date(), glucose: 100, minuteChange: -2), glucoseUnit: .mmolL, alarmLow: 70, alarmHigh: 180).preferredColorScheme($0)
            GlucoseView(glucose: SensorGlucose(id: 1, timeStamp: Date(), glucose: 190, minuteChange: 0), glucoseUnit: .mmolL, alarmLow: 70, alarmHigh: 180).preferredColorScheme($0)
            GlucoseView(glucose: nil, alarmLow: 70, alarmHigh: 180).preferredColorScheme($0)
        }
    }
}
