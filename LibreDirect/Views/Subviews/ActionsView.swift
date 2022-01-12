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
        if store.state.hasSelectedConnection {
            if store.state.isScanable {
                Button(
                    action: {
                        store.dispatch(.scanSensor)
                    },
                    label: {
                        Label("Scan sensor", systemImage: "viewfinder")
                    }
                )
            }

            if store.state.isPaired {
                if store.state.isConnectable {
                    Button(
                        action: {
                            withAnimation {
                                store.dispatch(.connectSensor)
                            }
                        },
                        label: {
                            Label("Connect sensor", systemImage: "play")
                        }
                    )
                } else if store.state.isDisconnectable {
                    Button(
                        action: {
                            showingDisconnectSensorAlert = true
                        },
                        label: {
                            Label("Disconnect sensor", systemImage: "stop")
                        }
                    ).alert(isPresented: $showingDisconnectSensorAlert) {
                        Alert(
                            title: Text("Are you sure you want to disconnect the sensor?"),
                            primaryButton: .destructive(Text("Disconnect")) {
                                withAnimation {
                                    store.dispatch(.disconnectSensor)
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }

            Button(
                action: {
                    withAnimation {
                        if store.state.isDisconnectable {
                            store.dispatch(.disconnectSensor)
                        }

                        if store.state.isPaired {
                            store.dispatch(.resetSensor)
                        }

                        store.dispatch(.pairSensor)
                    }
                },
                label: {
                    Label("Connect sensor", systemImage: "link")
                }
            )
        }
    }

    // MARK: Private

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
