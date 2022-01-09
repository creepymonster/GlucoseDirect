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
                
                if !store.state.isDisconnectable {
                    Button(
                        action: {
                            showingUnpairSensorAlert = true
                        },
                        label: {
                            Label("Unpair sensor", systemImage: "nosign")
                        }
                    ).alert(isPresented: $showingUnpairSensorAlert) {
                        Alert(
                            title: Text("Are you sure you want to unpair the sensor?"),
                            primaryButton: .destructive(Text("Unpair")) {
                                withAnimation {
                                    store.dispatch(.resetSensor)
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            } else if store.state.isPairable && !store.state.isBusy {
                Button(
                    action: {
                        withAnimation {
                            store.dispatch(.pairSensor)
                        }
                    },
                    label: {
                        Label("Pair sensor", systemImage: "link")
                    }
                )
            } else {
                Label("Please wait...", systemImage: "hourglass")
            }
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
