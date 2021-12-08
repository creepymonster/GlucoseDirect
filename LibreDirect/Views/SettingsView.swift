//
//  SettingsView.swift
//  LibreDirect
//

import SwiftUI

struct SettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
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
