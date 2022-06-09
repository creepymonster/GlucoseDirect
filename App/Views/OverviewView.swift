//
//  OverviewView.swift
//  GlucoseDirect
//

import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            List {
                if store.state.currentGlucose != nil {
                    GlucoseView().frame(maxWidth: .infinity)
                }

                if store.state.isConnectionPaired && !store.state.glucoseValues.isEmpty {
                    SnoozeView()
                }

                if !store.state.glucoseValues.isEmpty {
                    ChartView()
                }
                
                ConnectionView()
                SensorView()
            }.listStyle(.grouped)
        }
    }
}
