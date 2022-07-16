//
//  ListView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ListView

struct ListsView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        List {
            BloodGlucoseList()
            SensorGlucoseList()
            SensorErrorList()
        }.listStyle(.grouped)
    }
}
