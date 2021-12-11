//
//  AboutView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - AboutView

struct AboutView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
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

                    if store.state.isCollectingLogs {
                        Text("Log data will be processed...").foregroundColor(.gray)
                    } else {
                        Button(action: {
                            store.dispatch(.collectLogs)
                        }) {
                            Text("Send bug report")
                        }
                    }
                },
                header: {
                    Label("About \(appName)", systemImage: "info")
                }
            )
        }
    }

    // MARK: Private

    private let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
}

// MARK: - SendingLogsView

struct SendingLogsView: View {
    var body: some View {
        Text("Processing logs")
    }
}

// MARK: - AboutView_Previews

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            AboutView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
