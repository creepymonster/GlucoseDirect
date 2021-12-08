//
//  GlucoseListView.swift
//  LibreDirect
//

import SwiftUI

struct GlucoseListView: View {
    @State var value: Int = 0
    @State private var showingAddBloodGlucoseView = false
    @State private var showingAddBloodGlucoseAlert = false
    @State private var showingDeleteGlucoseValuesAlert = false
    @State var glucoseValues: [Glucose] = []

    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            List {
                if showingAddBloodGlucoseView {
                    Section(
                        content: {
                            NumberSelectorView(key: LocalizedString("Now"), value: value, step: 1, displayValue: value.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value -> Void in
                                self.value = value
                            }
                        },
                        header: {
                            Label("Add glucose value", systemImage: "drop.fill")
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
                                    action: { showingAddBloodGlucoseAlert = true },
                                    label: { Label("Add", systemImage: "checkmark") }
                                ).alert(isPresented: $showingAddBloodGlucoseAlert) {
                                    Alert(
                                        title: Text("Are you sure you want to add the new blood glucose value?"),
                                        primaryButton: .destructive(Text("Add")) {
                                            withAnimation {
                                                showingAddBloodGlucoseView = false
                                            }

                                            let glucose = Glucose(id: UUID(), timestamp: Date(), glucose: value, type: .bgm)
                                            store.dispatch(.addGlucose(glucose: glucose))
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                        }
                    )
                }

                Section(
                    content: {
                        ForEach(glucoseValues) { glucose in
                            HStack {
                                Text(glucose.timestamp.localDateTime)
                                Spacer()

                                if glucose.type == .bgm {
                                    Image(systemName: "drop.fill")
                                        .foregroundColor(Color.ui.red)
                                }

                                Text(glucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit, withUnit: true))
                                    .if(glucose.glucoseValue < store.state.alarmLow || glucose.glucoseValue > store.state.alarmHigh) { text in
                                        text.foregroundColor(Color.ui.red)
                                    }
                            }
                        }.onDelete { offsets in
                            Log.info("onDelete: \(offsets)")

                            let ids = offsets.map { i in
                                glucoseValues[i].id
                            }

                            glucoseValues.remove(atOffsets: offsets)

                            DispatchQueue.main.async {
                                ids.forEach { id in
                                    store.dispatch(.removeGlucose(id: id))
                                }
                            }
                        }
                    },
                    header: {
                        HStack {
                            Label("Glucose values", systemImage: "drop")
                            Spacer()

                            if !showingAddBloodGlucoseView {
                                Button(
                                    action: {
                                        value = 100
                                        withAnimation {
                                            showingAddBloodGlucoseView = true
                                        }
                                    },
                                    label: { Label("Add", systemImage: "plus") }
                                )
                            }
                        }
                    },
                    footer: {
                        if !store.state.glucoseValues.isEmpty {
                            Button(
                                action: { showingDeleteGlucoseValuesAlert = true },
                                label: { Label("Delete all", systemImage: "trash.fill") }
                            ).alert(isPresented: $showingDeleteGlucoseValuesAlert) {
                                Alert(
                                    title: Text("Are you sure you want to delete all glucose values?"),
                                    primaryButton: .destructive(Text("Delete")) {
                                        store.dispatch(.clearGlucoseValues)
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                    }
                )
            }
        }
        .onAppear {
            Log.info("onAppear")
            self.glucoseValues = store.state.glucoseValues.reversed()
        }
        .onChange(of: store.state.glucoseValues) { glucoseValues in
            Log.info("onChange")
            self.glucoseValues = glucoseValues.reversed()
        }
    }
}
