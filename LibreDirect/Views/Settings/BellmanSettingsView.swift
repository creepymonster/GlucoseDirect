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
                ToggleView(key: LocalizedString("Bellman alarm"), value: store.state.bellmanAlarm) { value -> Void in
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
                            Label("Bellman test alarm", systemImage: "ear.badge.checkmark")
                        }
                    )
                }
            },
            header: {
                Label("Bellman telephone transceiver BT", systemImage: "hearingdevice.ear")
            }
        )
    }
}
