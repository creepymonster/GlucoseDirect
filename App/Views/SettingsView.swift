//
//  SettingsView.swift
//  GlucoseDirect
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        List {
            SensorConnectorSettingsView()
            SensorConnectionConfigurationView()
            GlucoseSettingsView()
            AlarmSettingsView()
            NightscoutSettingsView()
            AppleExportSettingsView()
            BellmanSettingsView()
            AboutView()
        }.listStyle(.grouped)
    }
}
