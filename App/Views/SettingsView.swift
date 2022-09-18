//
//  SettingsView.swift
//  GlucoseDirect
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        VStack {
            List {
                SensorConnectorSettings()
                GlucoseSettingsView()
                AlarmSettingsView()
                NightscoutSettingsView()
                AppleExportSettingsView()
                BellmanSettingsView()
                AboutView()
                
                TunnelSettingsView()
            }.listStyle(.grouped)
        }
    }
}
