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
            header: Text(LocalizedString("Nightscout Settings"))
                .foregroundColor(.accentColor)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
        ) {
            ToggleView(key: LocalizedString("Nightscout Upload Enabled", comment: ""), value: store.state.nightscoutUpload) { value -> Void in
                store.dispatch(.setNightscoutUpload(enabled: value))
            }

            if store.state.nightscoutUpload {
                TextEditorView(key: LocalizedString("Nightscout Host", comment: ""), value: store.state.nightscoutHost) { value -> Void in
                    store.dispatch(.setNightscoutHost(host: value))
                }

                TextEditorView(key: LocalizedString("Nightscout API-Secret", comment: ""), value: store.state.nightscoutApiSecret) { value -> Void in
                    store.dispatch(.setNightscoutSecret(apiSecret: value))
                }
            }
        }
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
