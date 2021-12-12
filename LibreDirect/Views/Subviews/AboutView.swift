//
//  AboutView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - AboutView

struct AboutView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text(AppConfig.appVersion)
                }
                HStack {
                    Text("App Website")
                    Spacer()
                    Link("GitHub", destination: URL(string: AppConfig.RepoUrl)!)
                        .lineLimit(1)
                        .truncationMode(.head)
                }

                if store.state.isCollectingLogs {
                    HStack {
                        Image(systemName: "hourglass.bottomhalf.filled")
                        Text("Log data will be processed...")
                    }.foregroundColor(.gray)
                } else {
                    Button(action: {
                        store.dispatch(.collectLogs)
                    }) {
                        Text("Send log file")
                    }
                }
            },
            header: {
                Label("About \(AppConfig.appName)", systemImage: "info")
            }
        )
    }
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
