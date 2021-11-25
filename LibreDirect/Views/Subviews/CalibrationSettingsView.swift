//
//  CalibrationView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - CalibrationView

struct CalibrationSettingsView: View {
    private static let factor: Double = 1_000_000
    
    @State var value: Int = 0
    @State private var showingDeleteCalibrationsAlert = false
    @State private var showingAddCalibrationView = false
    @State private var showingAddCalibrationsAlert = false
    
    @EnvironmentObject var store: AppStore

    var slope: Double {
        Double(round(CalibrationSettingsView.factor * store.state.sensor!.customCalibration.slope) / CalibrationSettingsView.factor)
    }
    
    var intercept: Double {
        Double(round(CalibrationSettingsView.factor * store.state.sensor!.customCalibration.intercept) / CalibrationSettingsView.factor)
    }

    var body: some View {
        if let sensor = store.state.sensor, let lastGlucose = store.state.lastGlucose {
            Section(
                content: {
                    HStack {
                        Text("Factory Calibration i1")
                        Spacer()
                        Text(sensor.factoryCalibration.i1.description).textSelection(.enabled)
                    }
                    
                    HStack {
                        Text("Factory Calibration i2")
                        Spacer()
                        Text(sensor.factoryCalibration.i2.description).textSelection(.enabled)
                    }
                    
                    HStack {
                        Text("Factory Calibration i3")
                        Spacer()
                        Text(sensor.factoryCalibration.i3.description).textSelection(.enabled)
                    }
                    
                    HStack {
                        Text("Factory Calibration i4")
                        Spacer()
                        Text(sensor.factoryCalibration.i4.description).textSelection(.enabled)
                    }
                    
                    HStack {
                        Text("Factory Calibration i5")
                        Spacer()
                        Text(sensor.factoryCalibration.i5.description).textSelection(.enabled)
                    }
                    
                    HStack {
                        Text("Factory Calibration i6")
                        Spacer()
                        Text(sensor.factoryCalibration.i6.description).textSelection(.enabled)
                    }
                },
                header: {
                    Label("Sensor Factory Calibration", systemImage: "building")
                }
            )
            
            Section(
                content: {
                    if !showingAddCalibrationView {
                        HStack {
                            Text("Custom Calibration slope")
                            Spacer()
                            Text(slope.description).textSelection(.enabled)
                        }
                    
                        HStack {
                            Text("Custom Calibration intercept")
                            Spacer()
                            Text(intercept.description).textSelection(.enabled)
                        }
                    
                        ForEach(sensor.customCalibration) { calibration in
                            HStack {
                                Text(calibration.timestamp.localDateTime)
                                Spacer()
                                Text("\(calibration.x.asGlucose(unit: store.state.glucoseUnit)) = \(calibration.y.asGlucose(unit: store.state.glucoseUnit, withUnit: true))").textSelection(.enabled)
                            }
                        }.onDelete { offsets in
                            Log.info("onDelete: \(offsets)")
                            
                            let ids = offsets.map { i in
                                sensor.customCalibration[i].id
                            }
                            
                            DispatchQueue.main.async {
                                ids.forEach { id in
                                    store.dispatch(.removeCalibration(id: id))
                                }
                            }
                        }
                    } else {
                        NumberSelectorView(key: LocalizedString("Now"), value: value, step: 1, displayValue: value.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value -> Void in
                            self.value = value
                        }
                    }
                },
                header: {
                    HStack {
                        Label("Sensor Custom Calibration", systemImage: "person")
                        
                        if !showingAddCalibrationView {
                            Spacer()
                        
                            Button(
                                action: {
                                    value = lastGlucose.glucoseValue
                                    showingAddCalibrationView = true
                                },
                                label: { Label("Add", systemImage: "plus") }
                            )
                        }
                    }
                },
                footer: {
                    HStack {
                        if !showingAddCalibrationView {
                            if let sensor = store.state.sensor, !sensor.customCalibration.isEmpty {
                                Button(
                                    action: { showingDeleteCalibrationsAlert = true },
                                    label: { Label("Delete all", systemImage: "trash.fill") }
                                ).alert(isPresented: $showingDeleteCalibrationsAlert) {
                                    Alert(
                                        title: Text("Are you sure you want to delete all calibrations?"),
                                        primaryButton: .destructive(Text("Delete")) {
                                            store.dispatch(.clearCalibrations)
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                        } else {
                            Button(action: {
                                showingAddCalibrationView = false
                            }) {
                                Label("Cancel", systemImage: "multiply")
                            }
                                
                            Spacer()

                            Button(
                                action: { showingAddCalibrationsAlert = true },
                                label: { Label("Add", systemImage: "checkmark") }
                            ).alert(isPresented: $showingAddCalibrationsAlert) {
                                Alert(
                                    title: Text("Are you sure you want to add the new calibration?"),
                                    primaryButton: .destructive(Text("Add")) {
                                        showingAddCalibrationView = false
                                        store.dispatch(.addCalibration(bloodGlucose: value))
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                    }
                }
            )
        }
    }
}
