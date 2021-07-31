//
//  ContentView.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 06.07.21.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if store.state.isPaired && store.state.isDisconnectable {
                    GlucoseView(glucose: store.state.lastGlucose, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh).padding(.top)
                }

                ConnectionView(connectionState: store.state.connectionState, connectionError: store.state.connectionError, connectionErrorTimestamp: store.state.connectionErrorTimestamp).padding([.top, .horizontal])

                GlucoseChartView(glucoseValues: store.state.glucoseValues, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: 100).padding([.top, .horizontal]).frame(minHeight: 200)
                LifetimeView(sensor: store.state.sensor).padding([.top, .horizontal])
                DetailsView(sensor: store.state.sensor).padding([.top, .horizontal])
                InternalsView(sensor: store.state.sensor).padding([.top, .horizontal])

                NightscoutView().padding([.top, .horizontal])
                AlarmView().padding([.top, .horizontal])

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
