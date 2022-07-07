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
                if store.state.hasGlucoseValues {
                    GlucoseView()
                    
                    /*if #available(iOS 16.0, *) {
                        ChartView()
                    } else {
                        ChartViewFallback()
                    }*/
                    
                    ChartViewFallback()
                }

                ConnectionView()
                SensorView()
            }.listStyle(.grouped)
        }
    }
}
