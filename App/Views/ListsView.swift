//
//  ListView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ListsView

struct ListsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        List {
            if DirectConfig.insulinDeliveryInput {
                InsulinDeliveryList()
            }
            
            if DirectConfig.bloodGlucoseInput {
                BloodGlucoseList()
            }
            
            SensorGlucoseList()
            SensorErrorList()
            
            if DirectConfig.glucoseStatistics {
                StatisticsView()
            }
        }.listStyle(.grouped)
    }
}
