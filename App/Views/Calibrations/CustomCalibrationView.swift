//
//  CustomCalibrationView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - CustomCalibrationView

struct CustomCalibrationView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        if DirectConfig.customCalibration {
            Button("Add calibration", action: {
                showingAddCalibrationView = true
            }).sheet(isPresented: $showingAddCalibrationView, onDismiss: {
                showingAddCalibrationView = false
            }) {
                AddCalibrationView(glucoseSuggestion: store.state.latestSensorGlucose?.glucoseValue ?? 100, glucoseUnit: store.state.glucoseUnit) { value in
                    store.dispatch(.addCalibration(bloodGlucoseValue: value))
                }
            }
        }

        if DirectConfig.customCalibration || !store.state.customCalibration.isEmpty {
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
                            Text(verbatim: calibration.timestamp.toLocalDateTime())
                            Spacer()
                            Text(verbatim: "\(calibration.x.asGlucose(glucoseUnit: store.state.glucoseUnit)) = \(calibration.y.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))")
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let deletables = offsets.map { i in
                            (index: i, calibration: customCalibration[i])
                        }

                        deletables.forEach { delete in
                            customCalibration.remove(at: delete.index)
                            store.dispatch(.deleteCalibration(calibration: delete.calibration))
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
    }

    // MARK: Private

    private static let factor: Double = 1_000_000
    
    @State private var showingAddCalibrationView = false
    @State private var customCalibration: [CustomCalibration] = []

    private var slope: Double {
        Double(round(CustomCalibrationView.factor * customCalibration.slope) / CustomCalibrationView.factor)
    }

    private var intercept: Double {
        Double(round(CustomCalibrationView.factor * customCalibration.intercept) / CustomCalibrationView.factor)
    }
}
