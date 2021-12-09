//
//  SettingsView.swift
//  LibreDirect
//

import SwiftUI

struct SettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    var body: some View {
        VStack {
            Text("GlucoseDirect v\(appVersion!)").foregroundColor(Color.ui.blue).font(.caption)
            List {
                SensorConnectorSettings()
                GlucoseSettingsView()
                NightscoutSettingsView()
                AlarmSettingsView()
                CalendarExportSettingsView()
                OtherSettingsView()
            }
        }
    }

    // MARK: Private

    @State private var selectedConnectionId = ""
}
