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
                if store.state.latestSensorGlucose != nil {
                    GlucoseView()
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
