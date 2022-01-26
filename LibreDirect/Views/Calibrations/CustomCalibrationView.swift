//
//  CustomCalibrationView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - CustomCalibrationView

struct CustomCalibrationView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    @State var value: Int = 0
    @State var showingDeleteCalibrationsAlert = false
    @State var showingAddCalibrationView = false
    @State var showingAddCalibrationsAlert = false
    @State var customCalibration: [CustomCalibration] = []

    var body: some View {
        if showingAddCalibrationView {
            Section(
                content: {
                    NumberSelectorView(key: LocalizedString("Now"), value: value, step: 1, displayValue: value.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value in
                        self.value = value
                    }
                },
                header: {
                    Label("Add glucose for calibration", systemImage: "drop.fill")
                },
                footer: {
                    HStack {
                        Button(
                            action: {
                                withAnimation {
                                    showingAddCalibrationView = false
                                }
                            },
                            label: {
                                Label("Cancel", systemImage: "multiply")
                            }
                        )

                        Spacer()

                        Button(
                            action: {
                                showingAddCalibrationsAlert = true
                            },
                            label: {
                                Label("Add", systemImage: "checkmark")
                            }
                        ).alert(isPresented: $showingAddCalibrationsAlert) {
                            Alert(
                                title: Text("Are you sure you want to add the new calibration?"),
                                primaryButton: .destructive(Text("Add")) {
                                    withAnimation {
                                        store.dispatch(.addCalibration(glucoseValue: value))
                                        showingAddCalibrationView = false
                                    }
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
                HStack {
                    Text("Custom calibration slope")
                    Spacer()
                    Text(slope.description)
                }

                HStack {
                    Text("Custom calibration intercept")
                    Spacer()
                    Text(intercept.description)
                }

                ForEach(customCalibration) { calibration in
                    HStack {
                        Text(calibration.timestamp.toLocalDateTime())
                        Spacer()
                        Text("\(calibration.x.asGlucose(glucoseUnit: store.state.glucoseUnit)) = \(calibration.y.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))")
                    }
                }.onDelete { offsets in
                    AppLog.info("onDelete: \(offsets)")

                    let ids = offsets.map { i in
                        customCalibration[i].id
                    }

                    DispatchQueue.main.async {
                        ids.forEach { id in
                            store.dispatch(.removeCalibration(id: id))
                        }
                    }
                }
            },
            header: {
                HStack {
                    Label("Sensor custom calibration", systemImage: "person")

                    if let currentGlucose = store.state.currentGlucose, !showingAddCalibrationView {
                        Spacer()

                        Button(
                            action: {
                                withAnimation {
                                    value = currentGlucose.glucoseValue ?? 100
                                    showingAddCalibrationView = true
                                }
                            },
                            label: {
                                Label("Add", systemImage: "plus")
                            }
                        )
                    }
                }
            },
            footer: {
                if !showingAddCalibrationView && !customCalibration.isEmpty {
                    Button(
                        action: {
                            showingDeleteCalibrationsAlert = true
                        },
                        label: {
                            Label("Delete all", systemImage: "trash.fill")
                        }
                    ).alert(isPresented: $showingDeleteCalibrationsAlert) {
                        Alert(
                            title: Text("Are you sure you want to delete all calibrations?"),
                            primaryButton: .destructive(Text("Delete")) {
                                withAnimation {
                                    store.dispatch(.clearCalibrations)
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
        )
        .onAppear {
            AppLog.info("onAppear")
            self.customCalibration = store.state.customCalibration.reversed()
        }
        .onChange(of: store.state.customCalibration) { customCalibration in
            AppLog.info("onChange")
            self.customCalibration = customCalibration.reversed()
        }
    }

    // MARK: Private

    private static let factor: Double = 1_000_000

    private var slope: Double {
        Double(round(CustomCalibrationView.factor * customCalibration.slope) / CustomCalibrationView.factor)
    }

    private var intercept: Double {
        Double(round(CustomCalibrationView.factor * customCalibration.intercept) / CustomCalibrationView.factor)
    }
}
