//
//  BellmanSettingsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - BellmanSettingsView

struct BellmanSettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                ToggleView(key: LocalizedString("Bellman Visit alarm"), value: store.state.bellmanAlarm) { value -> Void in
                    store.dispatch(.setBellmanNotification(enabled: value))
                }

                if store.state.bellmanAlarm {
                    HStack {
                        Text("Connection state")
                        Spacer()
                        Text(store.state.bellmanConnectionState.localizedString)
                    }
                }

                if store.state.bellmanConnectionState == .connected {
                    Button(
                        action: {
                            store.dispatch(.bellmanTestAlarm)
                        },
                        label: {
                            Label("Bellman Visit test alarm", systemImage: "ear.badge.checkmark")
                        }
                    )
                }
            },
            header: {
                Label("Bellman Telephone Transceiver BT", systemImage: "hearingdevice.ear")
            }
        )
    }
}

// MARK: - BellmanSettingsView_Previews

struct BellmanSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            BellmanSettingsView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
