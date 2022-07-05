//
//  CalibrationView.swift
//  GlucoseDirect
//

import SwiftUI

struct CalibrationView: View {
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
