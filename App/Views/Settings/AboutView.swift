//
//  AboutView.swift
//  GlucoseDirect
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - AboutView

struct AboutView: View {
    // MARK: Internal
    @State private var importing = false

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Section(
            content: {
                HStack {
                    Text("App version")
                    Spacer()
                    Text(verbatim: "\(DirectConfig.appVersion) (\(DirectConfig.appBuild))")
                }

                if !gitShortSha.isEmpty {
                    HStack {
                        Text(verbatim: "Git commit")
                        Spacer()
                        Text(verbatim: gitShortSha).onTapGesture {
                            UIPasteboard.general.string = gitFullSha
                        }
                    }
                }

                if let appAuthor = DirectConfig.appAuthor, !appAuthor.isEmpty {
                    HStack {
                        Text("App author")
                        Spacer()
                        Text(verbatim: appAuthor)
                    }
                }

                if let appSupportMail = DirectConfig.appSupportMail, !appSupportMail.isEmpty {
                    HStack {
                        Text("App email")
                        Spacer()
                        Link(appSupportMail, destination: URL(string: "mailto:\(appSupportMail)")!)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }
                }

                HStack {
                    Text("App website")
                    Spacer()
                    Link("GitHub", destination: URL(string: DirectConfig.githubURL)!)
                        .lineLimit(1)
                        .truncationMode(.head)
                }

                HStack {
                    Text("App faq")
                    Spacer()
                    Link("GitHub", destination: URL(string: DirectConfig.faqURL)!)
                        .lineLimit(1)
                        .truncationMode(.head)
                }

                HStack {
                    Text("App facebook group")
                    Spacer()
                    Link("Facebook", destination: URL(string: DirectConfig.facebookURL)!)
                        .lineLimit(1)
                        .truncationMode(.head)
                }

                HStack {
                    Text("App donate")
                    Spacer()
                    Link("PayPal", destination: URL(string: DirectConfig.donateURL)!)
                        .lineLimit(1)
                        .truncationMode(.head)
                }

                HStack {
                    Text("App translation")
                    Spacer()
                    Link("Crowdin", destination: URL(string: DirectConfig.crowdinURL)!)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            },
            header: {
                Label("About \(DirectConfig.appName)", systemImage: "info")
            }
        )
        
        Section(
            content: {
                Button("Export as CSV", action: {
                    store.dispatch(.exportToUnknown)
                })
                
                Button("Export for Tidepool", action: {
                    store.dispatch(.exportToTidepool)
                })
                
                Button("Export for Glooko", action: {
                    store.dispatch(.exportToGlooko)
                })
            },
            header: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        )
        
        Button("Send database file", action: {
            store.dispatch(.sendDatabase)
        })

        Button("Send log file", action: {
            store.dispatch(.sendLogs)
        })
        
        Section(
            content: {
                Button("Import database file") {
                    importing = true
                }
                .fileImporter(
                    isPresented: $importing,
                    allowedContentTypes: [.database, UTType.init(filenameExtension: "sqlite")!, UTType.init(filenameExtension: "sqlite3")!],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let file):
                        if file.count == 0 {
                            DirectLog.warning("no files provided, aborting")
                            break
                        } else if file.count > 1 {
                            DirectLog.warning("more than 1 file provided, choosing first")
                        }

                        store.dispatch(.importDatabase(url: file[0]))
                    case .failure(let error):
                        DirectLog.error(error.localizedDescription)
                    }
                    importing = false
                }

            },
            header: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
        )

        if DirectConfig.isDebug {
            Section(
                content: {
                    Button("Debug alarm", action: {
                        store.dispatch(.debugAlarm)
                    })
                    
                    Button("Debug notification", action: {
                        store.dispatch(.debugNotification)
                    })
                },
                header: {
                    Label("Debug", systemImage: "testtube.2")
                }
            )
        }
    }

    // MARK: Private

    @State private var showingDeleteLogsAlert = false
}
