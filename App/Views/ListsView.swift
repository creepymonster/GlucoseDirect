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
            InsulinDeliveryList()
            BloodGlucoseList()
            SensorGlucoseList()
            SensorErrorList()
            StatisticsView()
        }.listStyle(.grouped)
    }
}
