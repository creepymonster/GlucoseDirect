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

                if let appName = appName, let appVersion = appVersion {
                    Section(
                        content: {
                            HStack {
                                Text("App Version")
                                Spacer()
                                Text(appVersion).foregroundColor(Color.accentColor)
                            }
                        },
                        header: {
                            Label("About \(appName)", systemImage: "info")
                        }
                    )
                }
            }
        }
    }

    // MARK: Private

    private let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    @State private var selectedConnectionId = ""
}
