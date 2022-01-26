//
//  OtherSettings.swift
//  LibreDirect
//

import SwiftUI

// MARK: - OtherSettingsView

struct OtherSettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                ToggleView(key: LocalizedString("Glucose badge"), value: store.state.glucoseBadge) { value -> Void in
                    store.dispatch(.setGlucoseBadge(enabled: value))
                }

                /*
                ToggleView(key: LocalizedString("Internal http server"), value: store.state.internalHttpServer) { value -> Void in
                    store.dispatch(.setInternalHttpServer(enabled: value))
                }

                if store.state.internalHttpServer {
                    let url = "http://localhost:\(AppConfig.internalHttpServerPort)/sgv.json"

                    Link(destination: URL(string: url)!, label: {
                        Label(url, systemImage: "link")
                    })
                    .lineLimit(1)
                    .truncationMode(.head)
                }
                */
                
                ToggleView(key: LocalizedString("Glucose read aloud"), value: store.state.readGlucose) { value -> Void in
                    store.dispatch(.setReadGlucose(enabled: value))
                }

                if store.state.readGlucose {
                    VStack(alignment: .leading) {
                        Text("Glucose values are read aloud:")
                            .fontWeight(.semibold)
                        
                        Text("Every 10 minutes")
                        Text("After disconnections")
                        Text("When the glucose trend changes")
                        Text("When a new alarm is triggered")
                    }
                    .foregroundColor(.gray)
                    .padding(.vertical, 5)
                }
            },
            header: {
                Label("Other Settings", systemImage: "flag.badge.ellipsis")
            }
        )
    }
}
