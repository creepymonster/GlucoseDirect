//
//  FactoryCalibrationView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - FactoryCalibrationView

struct FactoryCalibrationView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        if let sensor = store.state.sensor, let factoryCalibration = sensor.factoryCalibration {
            Section(
                content: {
                    HStack {
                        Text(verbatim: "i1")
                        Spacer()
                        Text(factoryCalibration.i1.description)
                    }

                    HStack {
                        Text(verbatim: "i2")
                        Spacer()
                        Text(factoryCalibration.i2.description)
                    }

                    HStack {
                        Text(verbatim: "i3")
                        Spacer()
                        Text(factoryCalibration.i3.description)
                    }

                    HStack {
                        Text(verbatim: "i4")
                        Spacer()
                        Text(factoryCalibration.i4.description)
                    }

                    HStack {
                        Text(verbatim: "i5")
                        Spacer()
                        Text(factoryCalibration.i5.description)
                    }

                    HStack {
                        Text(verbatim: "i6")
                        Spacer()
                        Text(factoryCalibration.i6.description)
                    }
                },
                header: {
                    Label("Sensor factory calibration", systemImage: "building")
                }
            )
        }
    }
}
