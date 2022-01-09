//
//  GlucoeOverviewView.swift
//  LibreDirect
//

import SwiftUI

struct GlucoeOverviewView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            List {
                if store.state.isScanable {
                    Button(
                        action: {
                            store.dispatch(.scanSensor)
                        },
                        label: {
                            Label("Scan sensor", systemImage: "viewfinder")
                        }
                    )
                }
                
                if store.state.currentGlucose != nil {
                    GlucoseView().frame(maxWidth: .infinity)
                }

                if store.state.isPaired || store.state.isScanable {
                    SnoozeView()
                }
                
                ChartView()
                ConnectionView()
                SensorView()
            }.listStyle(.grouped)
        }
    }
}
