//
//  NightscoutSettingsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - NightscoutSettingsView

struct NightscoutSettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                ToggleView(key: LocalizedString("Nightscout upload enabled", comment: ""), value: store.state.nightscoutUpload) { value -> Void in
                    withAnimation {
                        store.dispatch(.setNightscoutUpload(enabled: value))
                    }
                }

                if store.state.nightscoutUpload {
                    TextEditorView(key: LocalizedString("Nightscout host", comment: ""), value: store.state.nightscoutHost) { value -> Void in
                        store.dispatch(.setNightscoutHost(host: value))
                    }
                    
                    TextEditorView(key: LocalizedString("Nightscout API-Secret", comment: ""), value: store.state.nightscoutApiSecret) { value -> Void in
                        store.dispatch(.setNightscoutSecret(apiSecret: value))
                    }
                }
            },
            header: {
                Label("Nightscout settings", systemImage: "icloud.and.arrow.up")
            }
        )
    }
}

// MARK: - NightscoutView_Previews

struct NightscoutView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            NightscoutSettingsView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
