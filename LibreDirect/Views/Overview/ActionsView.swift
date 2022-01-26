//
//  ActionsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - ActionsView

struct ActionsView: View {
    @EnvironmentObject var store: AppStore
    @State var showingDisconnectSensorAlert = false
    @State var showingUnpairSensorAlert = false

    var body: some View {
        if store.state.hasSelectedConnection {
            Button(
                action: {
                    withAnimation {
                        if store.state.isDisconnectable {
                            store.dispatch(.disconnectSensor)
                        }
                        
                        store.dispatch(.pairSensor)
                    }
                },
                label: {
                    if store.state.isTransmitter {
                        Label("Find transmitter", systemImage: "magnifyingglass")
                    } else {
                        Label("Scan sensor", systemImage: "viewfinder")
                    }
                }
            )

            if store.state.isPaired {
                if store.state.isConnectable {
                    Button(
                        action: {
                            withAnimation {
                                store.dispatch(.connectSensor)
                            }
                        },
                        label: {
                            if store.state.isTransmitter {
                                Label("Connect transmitter", systemImage: "play")
                            } else {
                                Label("Connect sensor", systemImage: "play")
                            }
                        }
                    )
                } else if store.state.isDisconnectable {
                    Button(
                        action: {
                            showingDisconnectSensorAlert = true
                        },
                        label: {
                            if store.state.isTransmitter {
                                Label("Disconnect transmitter", systemImage: "stop")
                            } else {
                                Label("Disconnect sensor", systemImage: "stop")
                            }
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
        }
    }
}
