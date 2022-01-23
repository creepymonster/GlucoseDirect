//
//  CalibrationsView.swift
//  LibreDirect
//

import SwiftUI

struct CalibrationsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            List {
                CustomCalibrationView()
                FactoryCalibrationView()
            }.listStyle(.grouped)
        }
    }
}
