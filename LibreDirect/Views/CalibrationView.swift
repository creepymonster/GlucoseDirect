//
//  CalibrationView.swift
//  LibreDirect
//

import SwiftUI

struct CalibrationView: View {
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
