//
//  WatchApp.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - GlucoseDirectWatchApp

@main
struct GlucoseDirectWatchApp: App {
    @ObservedObject private var connectivityManager = WCSessionConnectivityService.shared

    var body: some Scene {
        WindowGroup {
            GlucoseWatchView(glucoseUnit: UserDefaults.shared.glucoseUnit, latestSensorGlucose: $connectivityManager.latestSensorGlucose)
        }
    }
}

// MARK: - GlucoseWatchView

struct GlucoseWatchView: View {
    var glucoseUnit: GlucoseUnit
    
    @Binding var latestSensorGlucose: SensorGlucose?
    
    var body: some View {
        VStack(spacing: 0) {
            if let latestGlucose = $latestSensorGlucose.wrappedValue {
                HStack(alignment: .lastTextBaseline, spacing: 30) {
                    Text(verbatim: latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .bold()
                        .font(.system(size: 40))
                        .foregroundColor(DirectHelper.getGlucoseColor(glucose: latestGlucose))

                    VStack(alignment: .center) {
                        Text(verbatim: latestGlucose.trend.description)

                        if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                            Text(verbatim: minuteChange)
                        } else {
                            Text(verbatim: "?")
                        }
                    }
                }

                HStack(alignment: .lastTextBaseline, spacing: 40) {
                    Text(verbatim: glucoseUnit.localizedDescription)
                    Text(latestGlucose.timestamp, style: .time)
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
    
    @State static var lowGlucose: SensorGlucose? = placeholderLowGlucose
    @State static var glucose: SensorGlucose? = placeholderGlucose
    @State static var highGlucose: SensorGlucose? = placeholderHighGlucose
    @State static var noData: SensorGlucose? = nil

    static var previews: some View {
        GlucoseWatchView(glucoseUnit: .mgdL, latestSensorGlucose: $lowGlucose)
            .previewDevice(device)
            .previewDisplayName("Low Glucose, mgdL")

        GlucoseWatchView(glucoseUnit: .mmolL, latestSensorGlucose: $lowGlucose)
            .previewDevice(device)
            .previewDisplayName("Low Glucose, mmo1L")

        GlucoseWatchView(glucoseUnit: .mgdL, latestSensorGlucose: $glucose)
            .previewDevice(device)
            .previewDisplayName("Glucose, mgdL")

        GlucoseWatchView(glucoseUnit: .mmolL, latestSensorGlucose: $glucose)
            .previewDevice(device)
            .previewDisplayName("Glucose, mmo1L")

        GlucoseWatchView(glucoseUnit: .mgdL, latestSensorGlucose: $highGlucose)
            .previewDevice(device)
            .previewDisplayName("High Glucose, mgdL")

        GlucoseWatchView(glucoseUnit: .mmolL, latestSensorGlucose: $highGlucose)
            .previewDevice(device)
            .previewDisplayName("High Glucose, mmo1L")
        
        
        GlucoseWatchView(glucoseUnit: .mmolL, latestSensorGlucose: $noData)
            .previewDevice(device)
            .previewDisplayName("No Data")

    }
}
