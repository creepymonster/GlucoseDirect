//
//  WatchApp.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - GlucoseDirectWatchApp

@main
struct GlucoseDirectWatchApp: App {
    var body: some Scene {
        WindowGroup {
            GlucoseWatchView(glucose: UserDefaults.shared.latestSensorGlucose, glucoseUnit: UserDefaults.shared.glucoseUnit)
        }
    }
}

// MARK: - GlucoseWatchView

struct GlucoseWatchView: View {
    var glucose: SensorGlucose?
    var glucoseUnit: GlucoseUnit

    var body: some View {
        VStack(spacing: 0) {
            if let latestGlucose = glucose {
                HStack(alignment: .lastTextBaseline, spacing: 20) {
                    Text(verbatim: latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .bold()
                        .font(.system(size: 96))
                        .foregroundColor(DirectHelper.getGlucoseColor(glucose: latestGlucose))

                    VStack(alignment: .leading) {
                        Text(verbatim: latestGlucose.trend.description)
                            .font(.system(size: 52))

                        if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                            Text(verbatim: minuteChange)
                        } else {
                            Text(verbatim: "?")
                        }
                    }
                }

                HStack(spacing: 40) {
                    Text(latestGlucose.timestamp, style: .time)
                    Text(verbatim: glucoseUnit.localizedDescription)
                }.opacity(0.5)

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

// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
    static var device: PreviewDevice {
        PreviewDevice(rawValue: "Apple Watch Series 7 (45mm)")
    }
    
    static var previews: some View {
        GlucoseWatchView(glucose: placeholderLowGlucose, glucoseUnit: .mgdL)
            .previewDevice(device)
        
        GlucoseWatchView(glucose: placeholderLowGlucose, glucoseUnit: .mmolL)
            .previewDevice(device)
        
        GlucoseWatchView(glucose: placeholderGlucose, glucoseUnit: .mgdL)
            .previewDevice(device)
        
        GlucoseWatchView(glucose: placeholderGlucose, glucoseUnit: .mmolL)
            .previewDevice(device)
        
        GlucoseWatchView(glucose: placeholderHighGlucose, glucoseUnit: .mgdL)
            .previewDevice(device)
        
        GlucoseWatchView(glucose: placeholderHighGlucose, glucoseUnit: .mmolL)
            .previewDevice(device)
    }
}
