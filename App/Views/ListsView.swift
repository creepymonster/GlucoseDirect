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
            Button("Add insulin", action: {
                showingAddInsulinView = true
            }).sheet(isPresented: $showingAddInsulinView, onDismiss: {
                showingAddInsulinView = false
            }) {
                LogInsulinView { start, end, units, insulinType in
                    let insulinDelivery = InsulinDelivery(id: UUID(), starts: start, ends: end, units: units, type: insulinType)
                    store.dispatch(.addInsulinDelivery(insulinDeliveryValues: [insulinDelivery]))
                }
            }
            
            Button("Add blood glucose", action: {
                showingAddBloodGlucoseView = true
            }).sheet(isPresented: $showingAddBloodGlucoseView, onDismiss: {
                showingAddBloodGlucoseView = false
            }) {
                LogBloodGlucoseView(glucoseUnit: store.state.glucoseUnit) { time, value in
                    let glucose = BloodGlucose(id: UUID(), timestamp: time, glucoseValue: value)
                    store.dispatch(.addBloodGlucose(glucoseValues: [glucose]))
                }
            }
            
            if DirectConfig.insulinDeliveryInput {
                InsulinDeliveryList()
            }
            
            if DirectConfig.bloodGlucoseInput {
                BloodGlucoseList()
            }
            
            SensorGlucoseList()
            
            if DirectConfig.glucoseErrors {
                SensorErrorList()
            }
            
            if DirectConfig.glucoseStatistics {
                StatisticsView()
            }
        }.listStyle(.grouped)
    }

    // MARK: Private

    @State private var showingAddInsulinView = false
    @State private var showingAddBloodGlucoseView = false
}
