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
                if !store.state.sensorGlucoseHistory.isEmpty || !store.state.bloodGlucoseValues.isEmpty {
                    GlucoseView()
                    
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
}
