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

                Button(
                    action: {
                        store.dispatch(.sendLogs)
                    },
                    label: {
                        Label("Send log file", systemImage: "square.and.arrow.up")
                    }
                )

                Button(
                    action: {
                        showingDeleteLogsAlert = true
                    },
                    label: {
                        Label("Delete log files", systemImage: "trash")
                    }
                ).alert(isPresented: $showingDeleteLogsAlert) {
                    Alert(
                        title: Text("Are you sure you want to delete all log files?"),
                        primaryButton: .destructive(Text("Delete all")) {
                            store.dispatch(.deleteLogs)
                        },
                        secondaryButton: .cancel()
                    )
                }
            },
            header: {
                Label("About \(AppConfig.appName)", systemImage: "info")
            }
        )
    }

    // MARK: Private

    @State private var showingDeleteLogsAlert = false
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
