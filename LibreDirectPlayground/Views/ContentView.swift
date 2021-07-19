//
//  ContentView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScrollView {
            GlucoseView(glucose: store.state.lastGlucose).padding(.top).padding(.leading)
            ConnectionView(connectionState: store.state.connectionState, connectionError: store.state.connectionError).padding(.top).padding(.leading)
            LifetimeView(sensor: store.state.sensor).padding(.top).padding(.leading)
            DetailsView(sensor: store.state.sensor).padding(.top).padding(.leading)
            InternalsView(sensor: store.state.sensor).padding(.top).padding(.leading)
            NightscoutView().padding(.top).padding(.leading)
            AlarmView().padding(.top).padding(.leading)
            ActionsView().padding(.top).padding(.leading)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ContentView().environmentObject(store)
    }
}
