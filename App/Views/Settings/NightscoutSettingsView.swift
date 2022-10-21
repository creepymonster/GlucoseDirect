//
//  NightscoutSettingsView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - NightscoutSettingsView

struct NightscoutSettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Section(
            content: {
                ToggleView(key: LocalizedString("Nightscout upload enabled"), value: store.state.nightscoutUpload) { value in
                    withAnimation {
                        store.dispatch(.setNightscoutUpload(enabled: value))
                    }
                }

                if store.state.nightscoutUpload {
                    VStack(alignment: .leading) {
                        Text("Nightscout url")
                        TextField("https://my-nightscout.herokuapp.com", text: nightscoutURL)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading) {
                        Text("Nightscout API-Secret")
                        SecureField("", text: nightscoutSecret)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            },
            header: {
                Label("Nightscout settings", systemImage: "icloud.and.arrow.up")
            }
        )
    }

    // MARK: Private

    private var nightscoutURL: Binding<String> {
        Binding(
            get: { store.state.nightscoutURL },
            set: { store.dispatch(.setNightscoutURL(url: $0)) }
        )
    }

    private var nightscoutSecret: Binding<String> {
        Binding(
            get: { store.state.nightscoutApiSecret },
            set: { store.dispatch(.setNightscoutSecret(apiSecret: $0)) }
        )
    }
}
