//
//  FactoryCalibrationView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - FactoryCalibrationView

struct FactoryCalibrationView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        if let sensor = store.state.sensor {
            Section(
                content: {
                    HStack {
                        Text("i1")
                        Spacer()
                        Text(sensor.factoryCalibration.i1.description)
                    }

                    HStack {
                        Text("i2")
                        Spacer()
                        Text(sensor.factoryCalibration.i2.description)
                    }

                    HStack {
                        Text("i3")
                        Spacer()
                        Text(sensor.factoryCalibration.i3.description)
                    }

                    HStack {
                        Text("i4")
                        Spacer()
                        Text(sensor.factoryCalibration.i4.description)
                    }

                    HStack {
                        Text("i5")
                        Spacer()
                        Text(sensor.factoryCalibration.i5.description)
                    }

                    HStack {
                        Text("i6")
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
