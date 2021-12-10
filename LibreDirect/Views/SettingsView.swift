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
                AlarmSettingsView()
                NightscoutSettingsView()
                CalendarExportSettingsView()
                OtherSettingsView()

                if let appName = appName, let appVersion = appVersion {
                    Section(
                        content: {
                            HStack {
                                Text("App Version")
                                Spacer()
                                Text(appVersion)
                            }
                            HStack {
                                Text("App Website")
                                Spacer()
                                Link("GitHub", destination: URL(string: AppConfig.RepoUrl)!)
                                    .lineLimit(1)
                                    .truncationMode(.head)
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
