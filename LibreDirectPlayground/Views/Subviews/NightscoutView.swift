//
//  SettingsView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct NightscoutView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        GroupBox(label: Text("NIGHTSCOUT")) {
            TextEditorView(key: "Host", value: store.state.nightscoutHost, completionHandler: { (value) -> Void in
                store.dispatch(.setNightscoutHost(host: value))
            })

            TextEditorView(key: "Secret", value: store.state.nightscoutApiSecret, completionHandler: { (value) -> Void in
                store.dispatch(.setNightscoutSecret(apiSecret: value))
            })
        }
    }
}

struct NightscoutView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        NightscoutView().environmentObject(store)
    }
}
