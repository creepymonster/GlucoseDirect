//
//  ListView.swift
//  GlucoseDirect
//

import SwiftUI

struct ListView: View {
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
                                        let glucose = Glucose.bloodGlucose(timestamp: Date(), glucoseValue: value)
                                        store.dispatch(.addGlucose(glucoseValues: [glucose]))

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

            Section(
                content: {
                    ForEach(glucoseValues) { glucose in
                        HStack {
                            Text(glucose.timestamp.toLocalDateTime())
                            Spacer()

                            if glucose.type == .bgm {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(Color.ui.red)
                            }

                            if let glucoseValue = glucose.glucoseValue {
                                Text(glucoseValue.asGlucose(unit: store.state.glucoseUnit, withUnit: true, precise: isPrecise(glucose: glucose)))
                                    .if(glucoseValue < store.state.alarmLow || glucoseValue > store.state.alarmHigh) { text in
                                        text.foregroundColor(Color.ui.red)
                                    }
                            } else {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(Color.ui.red)
                            }
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let ids = offsets.map { i in
                            glucoseValues[i].id
                        }

                        DispatchQueue.main.async {
                            ids.forEach { id in
                                if let index = glucoseValues.firstIndex(where: { value in
                                    value.id == id
                                }) {
                                    glucoseValues.remove(at: index)
                                }

                                store.dispatch(.removeGlucose(id: id))
                            }
                        }
                    }
                },
                header: {
                    Label("Glucose values", systemImage: "drop")
                }
            )
        }
        .listStyle(.grouped)
        .onAppear {
            DirectLog.info("onAppear")
            self.glucoseValues = store.state.glucoseValues.reversed()
        }
        .onChange(of: store.state.glucoseValues) { glucoseValues in
            DirectLog.info("onChange")
            self.glucoseValues = glucoseValues.reversed()
        }
    }

    // MARK: Private

    @State private var value: Int = 0
    @State private var showingAddBloodGlucoseView = false
    @State private var glucoseValues: [Glucose] = []

    private func isPrecise(glucose: Glucose) -> Bool {
        if glucose.type == .none {
            return false
        }

        if store.state.glucoseUnit == .mgdL || glucose.type == .bgm {
            return false
        }

        guard let glucoseValue = glucose.glucoseValue else {
            return false
        }

        return glucoseValue.isAlmost(store.state.alarmLow, store.state.alarmHigh)
    }
}
