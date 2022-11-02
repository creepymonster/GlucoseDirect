//
//  BellmanSettingsView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - BellmanSettingsView

struct BellmanSettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Section(
            content: {
                Toggle("Bellman alarm", isOn: bellmanAlarm)
                    .toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))

                if store.state.bellmanAlarm {
                    HStack {
                        Text("Connection state")
                        Spacer()
                        Text(store.state.bellmanConnectionState.localizedDescription)
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
                Label("Bellman Transceiver BT", systemImage: "hearingdevice.ear")
            }
        )
    }

    // MARK: Private

    private var bellmanAlarm: Binding<Bool> {
        Binding(
            get: { store.state.bellmanAlarm },
            set: { store.dispatch(.setBellmanNotification(enabled: $0)) }
        )
    }
}
