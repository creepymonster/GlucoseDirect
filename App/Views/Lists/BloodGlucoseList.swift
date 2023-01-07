//
//  BloodGlucoseList.swift
//  GlucoseDirectApp
//

import SwiftUI

struct BloodGlucoseList: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
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

            CollapsableSection(teaser: Text(getTeaser(bloodGlucoseValues.count)), header: Label("Blood glucose values", systemImage: "drop"), collapsed: true, collapsible: !bloodGlucoseValues.isEmpty) {
                if bloodGlucoseValues.isEmpty {
                    Text(getTeaser(bloodGlucoseValues.count))
                } else {
                    ForEach(bloodGlucoseValues) { bloodGlucose in
                        HStack {
                            Text(verbatim: bloodGlucose.timestamp.toLocalDateTime())
                            Spacer()

                            Text(verbatim: bloodGlucose.glucoseValue.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))
                                .if(bloodGlucose.glucoseValue < store.state.alarmLow || bloodGlucose.glucoseValue > store.state.alarmHigh) { text in
                                    text.foregroundColor(Color.ui.red)
                                }
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let deletables = offsets.map { i in
                            (index: i, glucose: bloodGlucoseValues[i])
                        }

                        deletables.forEach { delete in
                            bloodGlucoseValues.remove(at: delete.index)
                            store.dispatch(.deleteBloodGlucose(glucose: delete.glucose))
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .onAppear {
            DirectLog.info("onAppear")
            self.bloodGlucoseValues = store.state.bloodGlucoseValues.reversed()
        }
        .onChange(of: store.state.bloodGlucoseValues) { glucoseValues in
            DirectLog.info("onChange")
            self.bloodGlucoseValues = glucoseValues.reversed()
        }
    }

    // MARK: Private

    @State private var value: Int = 0
    @State private var showingAddBloodGlucoseView = false
    @State private var bloodGlucoseValues: [BloodGlucose] = []

    private func getTeaser(_ count: Int) -> String {
        return count.pluralizeLocalization(singular: "%@ Entry", plural: "%@ Entries")
    }

    private func isPrecise(glucose: SensorGlucose) -> Bool {
        if store.state.glucoseUnit == .mgdL {
            return false
        }

        return glucose.glucoseValue.isAlmost(store.state.alarmLow, store.state.alarmHigh)
    }
}
