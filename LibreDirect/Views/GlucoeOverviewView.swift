//
//  GlucoeOverviewView.swift
//  LibreDirect
//

import SwiftUI

struct GlucoeOverviewView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            ActionsView()

            List {
                if store.state.currentGlucose != nil {
                    GlucoseView().frame(maxWidth: .infinity)
                }

                ChartView()
                SensorView()
            }.listStyle(.grouped)
        }
    }
}
