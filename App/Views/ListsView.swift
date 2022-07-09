//
//  ListView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ListView

struct ListsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        List {
            if showingAddBloodGlucoseView {
                Section(
                    content: {
                        NumberSelectorView(key: LocalizedString("Now"), value: value, step: 1, displayValue: value.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value in
                            self.value = value
                        }
                    },
                    header: {
                        Label("Add blood glucose", systemImage: "drop.fill")
                    },
                    footer: {
                        HStack {
                            Button(action: {
                                withAnimation {
                                    showingAddBloodGlucoseView = false
                                }
                            }) {
                                Label("Cancel", systemImage: "multiply")
                            }

                            Spacer()

                            Button(
                                action: {
                                    withAnimation {
                                        let glucose = BloodGlucose(id: UUID(), timestamp: Date(), glucoseValue: value)
                                        store.dispatch(.addBloodGlucose(glucoseValues: [glucose]))

                                        showingAddBloodGlucoseView = false
                                    }
                                },
                                label: {
                                    Label("Add", systemImage: "checkmark")
                                }
                            )
                        }.padding(.bottom)
                    }
                )
            } else {
                Button("Add blood glucose", action: {
                    withAnimation {
                        value = 100
                        showingAddBloodGlucoseView = true
                    }
                })
            }

            CollapsableSection(teaser: Text(getTeaser(bloodGlucoseValues.count)), header: Label("BGM", systemImage: "drop"), collapsed: true, collapsible: !bloodGlucoseValues.isEmpty) {
                if bloodGlucoseValues.isEmpty {
                    Text(getTeaser(bloodGlucoseValues.count))
                } else {
                    ForEach(bloodGlucoseValues) { glucose in
                        HStack {
                            Text(glucose.timestamp.toLocalDateTime())
                            Spacer()

                            Text(glucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit, withUnit: true))
                                .if(glucose.glucoseValue < store.state.alarmLow || glucose.glucoseValue > store.state.alarmHigh) { text in
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

            CollapsableSection(teaser: Text(getTeaser(sensorGlucoseValues.count)), header: Label("CGM", systemImage: "sensor.tag.radiowaves.forward"), collapsed: true, collapsible: !sensorGlucoseValues.isEmpty) {
                if sensorGlucoseValues.isEmpty {
                    Text(getTeaser(sensorGlucoseValues.count))
                } else {
                    ForEach(sensorGlucoseValues) { glucose in
                        HStack {
                            Text(glucose.timestamp.toLocalDateTime())
                            Spacer()

                            Text(glucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit, withUnit: true, precise: isPrecise(glucose: glucose)))
                                .if(glucose.glucoseValue < store.state.alarmLow || glucose.glucoseValue > store.state.alarmHigh) { text in
                                    text.foregroundColor(Color.ui.red)
                                }
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let deletables = offsets.map { i in
                            (index: i, glucose: sensorGlucoseValues[i])
                        }

                        deletables.forEach { delete in
                            sensorGlucoseValues.remove(at: delete.index)
                            store.dispatch(.deleteSensorGlucose(glucose: delete.glucose))
                        }
                    }
                }
            }

            CollapsableSection(teaser: Text(getTeaser(sensorErrorValues.count)), header: Label("Errors", systemImage: "exclamationmark.triangle"), collapsed: true, collapsible: !sensorErrorValues.isEmpty) {
                if sensorErrorValues.isEmpty {
                    Text(getTeaser(sensorErrorValues.count))
                } else {
                    ForEach(sensorErrorValues) { error in
                        HStack {
                            Text(error.timestamp.toLocalDateTime())
                            Spacer()
                            Text(":'(")
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let deletables = offsets.map { i in
                            (index: i, error: sensorErrorValues[i])
                        }

                        deletables.forEach { delete in
                            sensorErrorValues.remove(at: delete.index)
                            store.dispatch(.deleteSensorError(error: delete.error))
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .onAppear {
            DirectLog.info("onAppear")
            self.sensorGlucoseValues = store.state.sensorGlucoseValues.reversed()
            self.bloodGlucoseValues = store.state.bloodGlucoseValues.reversed()
            self.sensorErrorValues = store.state.sensorErrorValues.reversed()
        }
        .onChange(of: store.state.sensorGlucoseValues) { glucoseValues in
            DirectLog.info("onChange")
            self.sensorGlucoseValues = glucoseValues.reversed()
        }
        .onChange(of: store.state.bloodGlucoseValues) { glucoseValues in
            DirectLog.info("onChange")
            self.bloodGlucoseValues = glucoseValues.reversed()
        }
        .onChange(of: store.state.sensorErrorValues) { errorValues in
            DirectLog.info("onChange")
            self.sensorErrorValues = errorValues.reversed()
        }
    }

    // MARK: Private

    @State private var value: Int = 0
    @State private var showingAddBloodGlucoseView = false
    @State private var sensorGlucoseValues: [SensorGlucose] = []
    @State private var bloodGlucoseValues: [BloodGlucose] = []
    @State private var sensorErrorValues: [SensorError] = []

    private func getTeaser(_ count: Int) -> String {
        if count == 1 {
            return "\(count) Entry..."
        }

        return "\(count) Entries"
    }

    private func isPrecise(glucose: SensorGlucose) -> Bool {
        if store.state.glucoseUnit == .mgdL {
            return false
        }

        return glucose.glucoseValue.isAlmost(store.state.alarmLow, store.state.alarmHigh)
    }
}
