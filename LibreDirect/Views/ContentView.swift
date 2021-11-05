//
//  ContentView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import CoreNFC
import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let lastGlucose = store.state.lastGlucose {
                    GlucoseView(glucose: lastGlucose, glucoseUnit: store.state.glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh).padding([.top])
                }

                if store.state.connectionState == .connected {
                    AlarmSnoozeView().padding([.top, .horizontal])
                }

                ConnectionView(connectionState: store.state.connectionState, connectionError: store.state.connectionError, connectionErrorTimestamp: store.state.connectionErrorTimeStamp, missedReadings: store.state.missedReadings).padding([.top, .horizontal])

                if !store.state.isPairable {
                    GlucoseChartView(glucoseValues: store.state.glucoseValues, glucoseUnit: store.state.glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: 100).padding([.top, .horizontal]).frame(minHeight: 200)
                    LifetimeView(sensor: store.state.sensor).padding([.top, .horizontal])
                    DetailsView(sensor: store.state.sensor).padding([.top, .horizontal])

                    AlarmSettingsView().padding([.top, .horizontal])
                    NightscoutSettingsView().padding([.top, .horizontal])
                    GlucoseSettingsView().padding([.top, .horizontal])
                }

                ActionsView().padding([.top, .horizontal])
            }
        }
    }

    var nfcErrorView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.red, lineWidth: 0)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color.red))
                .frame(width: 320, height: 120)
                .clipped()

            VStack {
                Text("Sorry, an NFC enabled iPhone is required to use LibreDirect :'(")
            }
            .frame(width: 300, height: 90)
            .foregroundColor(Color.white)
        }.padding()
    }

    var body: some View {
        if NFCTagReaderSession.readingAvailable {
            contentView
        } else {
            nfcErrorView
        }
    }
}

// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            ContentView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
