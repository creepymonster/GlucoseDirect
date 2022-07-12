//
//  CalibrationView.swift
//  GlucoseDirect
//

import SwiftUI

struct CalibrationsView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        VStack {
            List {
                CustomCalibrationView()
                FactoryCalibrationView()
            }.listStyle(.grouped)
        }
    }
}
