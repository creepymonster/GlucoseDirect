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
            GlucoseView(glucose: store.state.lastGlucose).padding(.top)
            
            ConnectionView(connectionState: store.state.connectionState, connectionError: store.state.connectionError).padding()
            LifetimeView(sensor: store.state.sensor).padding()
            DetailsView(sensor: store.state.sensor).padding()
            InternalsView(sensor: store.state.sensor).padding()
            
            NightscoutView().padding()
            AlarmView().padding()
            
            ActionsView().padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ContentView().environmentObject(store)
    }
}
