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
            TextEditorView(key: LocalizedBundleString("Nightscout Host", comment: ""), value: store.state.nightscoutHost, completionHandler: { (value) -> Void in
                store.dispatch(.setNightscoutHost(host: value))
            })

            TextEditorView(key: LocalizedBundleString("Nightscout API-Secret", comment: ""), value: store.state.nightscoutApiSecret, completionHandler: { (value) -> Void in
                store.dispatch(.setNightscoutSecret(apiSecret: value))
            })
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
