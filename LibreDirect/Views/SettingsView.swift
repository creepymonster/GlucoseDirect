//
//  SettingsView.swift
//  LibreDirect
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            List {
                SensorConnectorSettings()
                GlucoseSettingsView()
                AlarmSettingsView()
                NightscoutSettingsView()
                CalendarExportSettingsView()
                ReadAloudSettingsView()
                OtherSettingsView()
                AboutView()
            }.listStyle(.grouped)
        }
    }
}
