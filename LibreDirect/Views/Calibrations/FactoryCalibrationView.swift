//
//  FactoryCalibrationView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - FactoryCalibrationView

struct FactoryCalibrationView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        if let sensor = store.state.sensor {
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
