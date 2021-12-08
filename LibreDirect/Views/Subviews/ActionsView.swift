
//
//  ActionsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - ActionsView

struct ActionsView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
        HStack {
            if store.state.hasSelectedConnection && store.state.isPaired {
                if !store.state.isDisconnectable {
                    Button(
                        action: { showingUnpairSensorAlert = true },
                        label: { Label("Unpair sensor", systemImage: "arrow.uturn.backward") }
                    ).alert(isPresented: $showingUnpairSensorAlert) {
                        Alert(
                            title: Text("Are you sure you want to unpair the sensor?"),
                            primaryButton: .destructive(Text("Unpair")) {
                                store.dispatch(.resetTransmitter)
                                store.dispatch(.resetSensor)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }

                if store.state.isConnectable {
                    Spacer()

                    Button(action: { store.dispatch(.connectSensor) }) {
                        Label("Connect sensor", systemImage: "play")
                    }
                } else if store.state.isDisconnectable {
                    Button(
                        action: { showingDisconnectSensorAlert = true },
                        label: { Label("Disconnect sensor", systemImage: "stop") }
                    ).alert(isPresented: $showingDisconnectSensorAlert) {
                        Alert(
                            title: Text("Are you sure you want to disconnect the sensor?"),
                            primaryButton: .destructive(Text("Disconnect")) {
                                store.dispatch(.disconnectSensor)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            } else if store.state.hasSelectedConnection && store.state.connectionState != .pairing && store.state.connectionState != .scanning && store.state.connectionState != .connecting {
                Button(action: { store.dispatch(.pairSensor) }) {
                    Label("Pair sensor", systemImage: "arrow.uturn.forward")
                }
            } else {
                Text("...")
            }
        }
        .padding([.top, .horizontal])
    }

    // MARK: Private

    @State private var showingDeleteLogsAlert = false
    @State private var showingDisconnectSensorAlert = false
    @State private var showingUnpairSensorAlert = false
}

// MARK: - ActionsView_Previews

struct ActionsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            ActionsView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
