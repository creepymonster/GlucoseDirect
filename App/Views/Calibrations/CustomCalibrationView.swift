//
//  CustomCalibrationView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - CustomCalibrationView

struct CustomCalibrationView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

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
                                withAnimation {
                                    store.dispatch(.addCalibration(bloodGlucoseValue: value))
                                    showingAddCalibrationView = false
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
            Button("Add calibration", action: {
                withAnimation {
                    value = 100
                    showingAddCalibrationView = true
                }
            })
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
                    DirectLog.info("onDelete: \(offsets)")

                    let ids = offsets.map { i in
                        customCalibration[i].id
                    }

                    DispatchQueue.main.async {
                        ids.forEach { id in
                            if let index = customCalibration.firstIndex(where: { value in
                                value.id == id
                            }) {
                                customCalibration.remove(at: index)
                            }

                            store.dispatch(.removeCalibration(id: id))
                        }
                    }
                }
            },
            header: {
                Label("Sensor custom calibration", systemImage: "person")
            }
        ).onAppear {
            DirectLog.info("onAppear")
            self.customCalibration = store.state.customCalibration.reversed()
        }.onChange(of: store.state.customCalibration) { customCalibration in
            DirectLog.info("onChange")
            self.customCalibration = customCalibration.reversed()
        }
    }

    // MARK: Private

    private static let factor: Double = 1_000_000

    @State private var value: Int = 0
    @State private var showingAddCalibrationView = false
    @State private var customCalibration: [CustomCalibration] = []

    private var slope: Double {
        Double(round(CustomCalibrationView.factor * customCalibration.slope) / CustomCalibrationView.factor)
    }

    private var intercept: Double {
        Double(round(CustomCalibrationView.factor * customCalibration.intercept) / CustomCalibrationView.factor)
    }
}
