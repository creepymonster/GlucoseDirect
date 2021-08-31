//
//  ContentView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI
import LibreDirectLibrary

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let lastGlucose = store.state.lastGlucose {
                    GlucoseView(glucose: lastGlucose, glucoseUnit: store.state.glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh).padding([.top, .bottom])
                }

                ConnectionView(connectionState: store.state.connectionState, connectionError: store.state.connectionError, connectionErrorTimestamp: store.state.connectionErrorTimeStamp).padding([.horizontal])

                AlarmSnoozeView().padding([.top, .horizontal])
                GlucoseChartView(glucoseValues: store.state.glucoseValues, glucoseUnit: store.state.glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: 100).padding([.top, .horizontal]).frame(minHeight: 200)
                LifetimeView(sensor: store.state.sensor).padding([.top, .horizontal])
                DetailsView(sensor: store.state.sensor).padding([.top, .horizontal])

                GlucoseSettingsView().padding([.top, .horizontal])
                AlarmSettingsView().padding([.top, .horizontal])
                NightscoutSettingsView().padding([.top, .horizontal])

                ActionsView().padding([.top, .horizontal])
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            ContentView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
