//
//  NightscoutSettingsView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 02.08.21.
//

import SwiftUI
import LibreDirectLibrary

struct NightscoutSettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        GroupBox(label: Text("Nightscout Settings").padding(.bottom).foregroundColor(.accentColor)) {
            ToggleView(key: LocalizedString("Nightscout Host Enabled", comment: ""), value: store.state.nightscoutUpload) { (value) -> Void in
                store.dispatch(.setNightscoutUpload(enabled: value))
            }

            if store.state.nightscoutUpload {
                TextEditorView(key: LocalizedString("Nightscout Host", comment: ""), value: store.state.nightscoutHost) { (value) -> Void in
                    store.dispatch(.setNightscoutHost(host: value))
                }

                TextEditorView(key: LocalizedString("Nightscout API-Secret", comment: ""), value: store.state.nightscoutApiSecret) { (value) -> Void in
                    store.dispatch(.setNightscoutSecret(apiSecret: value))
                }
            }
        }
    }
}

struct NightscoutView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            NightscoutSettingsView().environmentObject(store).preferredColorScheme($0)
        }
    }
}

