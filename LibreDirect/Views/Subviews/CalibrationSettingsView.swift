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
        Group {
            if let sensor = store.state.sensor, let lastGlucose = store.state.lastGlucose {
                if showingAddCalibrationView {
                    Section(
                        content: {
                            NumberSelectorView(key: LocalizedString("Now"), value: value, step: 1, displayValue: value.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value -> Void in
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
                    
                        ForEach(sensor.customCalibration) { calibration in
                            HStack {
                                Text(calibration.timestamp.localDateTime)
                                Spacer()
                                Text("\(calibration.x.asGlucose(glucoseUnit: store.state.glucoseUnit)) = \(calibration.y.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))")
                            }
                        }.onDelete { offsets in
                            AppLog.info("onDelete: \(offsets)")
                            
                            let ids = offsets.map { i in
                                sensor.customCalibration[i].id
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
                        
                            if !showingAddCalibrationView {
                                Spacer()
                        
                                Button(
                                    action: {
                                        withAnimation {
                                            value = lastGlucose.glucoseValue ?? 100
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
                        if !showingAddCalibrationView {
                            if let sensor = store.state.sensor, !sensor.customCalibration.isEmpty {
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
                    }
                )
            
                Section(
                    content: {
                        HStack {
                            Text("Factory calibration i1")
                            Spacer()
                            Text(sensor.factoryCalibration.i1.description)
                        }
                    
                        HStack {
                            Text("Factory calibration i2")
                            Spacer()
                            Text(sensor.factoryCalibration.i2.description)
                        }
                    
                        HStack {
                            Text("Factory calibration i3")
                            Spacer()
                            Text(sensor.factoryCalibration.i3.description)
                        }
                    
                        HStack {
                            Text("Factory calibration i4")
                            Spacer()
                            Text(sensor.factoryCalibration.i4.description)
                        }
                    
                        HStack {
                            Text("Factory calibration i5")
                            Spacer()
                            Text(sensor.factoryCalibration.i5.description)
                        }
                    
                        HStack {
                            Text("Factory calibration i6")
                            Spacer()
                            Text(sensor.factoryCalibration.i6.description)
                        }
                    },
                    header: {
                        Label("Sensor factory calibration", systemImage: "building")
                    }
                )
            }
        }
    }
}
