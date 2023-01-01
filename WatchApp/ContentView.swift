//
//  ContentView.swift
//  GlucoseDirectWatchApp
//

import SwiftUI

// MARK: - GlucoseView

struct GlucoseView: View {
    
    var glucoseUnit: GlucoseUnit {
        UserDefaults.shared.glucoseUnit ?? .mgdL
    }
    
    var glucose: SensorGlucose? {
        UserDefaults.shared.latestSensorGlucose
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let latestGlucose = glucose {
                HStack(alignment: .lastTextBaseline, spacing: 20) {
                    if latestGlucose.type != .high {
                        Text(verbatim: latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                            .font(.system(size: 96))
                            .foregroundColor(GlucoseHelper.getGlucoseColor(glucose: latestGlucose))
                        
                        VStack(alignment: .leading) {
                            Text(verbatim: latestGlucose.trend.description)
                                .font(.system(size: 52))
                            
                            if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                                Text(verbatim: minuteChange)
                            } else {
                                Text(verbatim: "?")
                            }
                        }
                    } else {
                        Text("HIGH")
                            .font(.system(size: 96))
                            .foregroundColor(GlucoseHelper.getGlucoseColor(glucose: latestGlucose))
                    }
                }
                
                if let warning = GlucoseHelper.warning {
                    Text(verbatim: warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.ui.red)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                } else {
                    HStack(spacing: 40) {
                        Text(latestGlucose.timestamp, style: .time)
                        Text(verbatim: glucoseUnit.localizedDescription)
                    }.opacity(0.5)
                }
                
            } else {
                Text("No Data")
                    .font(.system(size: 52))
                    .foregroundColor(Color.ui.red)
                
                Text(Date(), style: .time)
                    .opacity(0.5)
            }
        }
    }
}
