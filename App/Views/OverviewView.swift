//
//  OverviewView.swift
//  GlucoseDirect
//

import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        List {
            GlucoseView()
                .listRowSeparator(.hidden)

            if !store.state.sensorGlucoseValues.isEmpty || !store.state.bloodGlucoseValues.isEmpty {
                if #available(iOS 16.0, *) {
                    ChartView()
                } else {
                    ChartViewCompatibility()
                }
            }

            ConnectionView()
            SensorView()
        }.listStyle(.grouped)
    }
}
