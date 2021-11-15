//
//  CalibrationView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - CalibrationView

struct CalibrationView: View {
    @State var value: Int = 0
    @State private var showingDeleteCalibrationsAlert = false
    @EnvironmentObject var store: AppStore

    var customCalibrationRows: [ListViewRow] {
        let factor: Double = 1_000_000
        
        var rows: [ListViewRow] = []
        
        guard let sensor = store.state.sensor else {
            return rows
        }
        
        let slope = Double(round(factor * sensor.customCalibration.slope) / factor)
        let intercept = Double(round(factor * sensor.customCalibration.intercept) / factor)
        
        rows.append(ListViewRow(key: "Custom Calibration slope", value: slope.description))
        rows.append(ListViewRow(key: "Custom Calibration intercept", value: intercept.description))
        
        store.state.sensor?.customCalibration.forEach { calibration in
            rows.append(ListViewRow(key: calibration.date.localDateTime, value: "\(calibration.x.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) = \(calibration.y.asGlucose(unit: store.state.glucoseUnit, withUnit: true))"))
        }
        
        return rows
    }

    var body: some View {
        ListView(header: "Sensor Factory Calibration", rows: [
            ListViewRow(key: "Factory Calibration i1", value: store.state.sensor?.factoryCalibration.i1.description),
            ListViewRow(key: "Factory Calibration i2", value: store.state.sensor?.factoryCalibration.i2.description),
            ListViewRow(key: "Factory Calibration i3", value: store.state.sensor?.factoryCalibration.i3.description),
            ListViewRow(key: "Factory Calibration i4", value: store.state.sensor?.factoryCalibration.i4.description),
            ListViewRow(key: "Factory Calibration i5", value: store.state.sensor?.factoryCalibration.i5.description),
            ListViewRow(key: "Factory Calibration i6", value: store.state.sensor?.factoryCalibration.i6.description),
        ])
        
        ListView(header: "Sensor Custom Calibration", rows: customCalibrationRows)

        if store.state.showCalibrationView {
            NumberSelectorView(key: Date().localDateTime, value: value, step: 1, displayValue: value.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value -> Void in
                self.value = value
            }
                
            HStack {
                Spacer()
                    
                Button(action: {
                    store.dispatch(.hideCalibrationView)
                }) {
                    Label("Cancel Calibration", systemImage: "multiply")
                }
 
                Button(action: {
                    store.dispatch(.addCalibration(bloodGlucose: value))
                }) {
                    Label("Save Calibration", systemImage: "checkmark")
                }
            }.padding(.top, 5)
        } else {
            HStack {
                if let sensor = store.state.sensor, !sensor.customCalibration.isEmpty {
                    Button(
                        action: { showingDeleteCalibrationsAlert = true },
                        label: { Label("Delete Calibrations", systemImage: "trash.fill") }
                    ).alert(isPresented: $showingDeleteCalibrationsAlert) {
                        Alert(
                            title: Text("Are you sure you want to delete all calibrations?"),
                            primaryButton: .destructive(Text("Unpair")) {
                                store.dispatch(.clearCalibrations)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                        
                Spacer()
                        
                Button(action: {
                    if let currentGlucose = store.state.currentGlucose {
                        value = currentGlucose.glucoseValue
                    }
                            
                    store.dispatch(.showCalibrationView)
                }) {
                    Label("Add Calibration", systemImage: "plus")
                }
            }.padding(.top, 10)
        }
    }
}

// MARK: - CalibrationView_Previews

struct CalibrationView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            CalibrationView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
