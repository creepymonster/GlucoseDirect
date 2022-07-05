//
//  OverviewView.swift
//  GlucoseDirect
//

import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        VStack {
            List {
                if store.state.latestSensorGlucose != nil {
                    GlucoseView()
                }

                if !store.state.glucoseValues.isEmpty {
                    if #available(iOS 16.0, *) {
                        ChartView()
                    } else {
                        ChartViewFallback()
                    }
                }

                ConnectionView()
                SensorView()
            }.listStyle(.grouped)
        }
    }
}
