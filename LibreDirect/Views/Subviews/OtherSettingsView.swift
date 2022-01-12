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
            },
            header: {
                Label("Other Settings", systemImage: "flag.badge.ellipsis")
            }
        )
    }
}

// MARK: - OtherSettings_Previews

struct OtherSettings_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            OtherSettingsView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
