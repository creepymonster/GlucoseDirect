//
//  ActionsView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ActionsView

struct ActionsView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
        if store.state.hasSelectedConnection {
            if store.state.isTransmitter && !store.state.isConnectionPaired {
                Button(
                    action: {
                        withAnimation {
                            if store.state.isDisconnectable {
                                store.dispatch(.disconnectConnection)
                            }

                            store.dispatch(.pairConnection)
                        }
                    },
                    label: {
                        Text("Find transmitter")
                    }
                ).disabled(store.state.isBusy)
            }

            if store.state.isSensor {
                Button(
                    action: {
                        withAnimation {
                            if store.state.isDisconnectable {
                                store.dispatch(.disconnectConnection)
                            }

                            store.dispatch(.pairConnection)
                        }
                    },
                    label: {
                        Text("Scan sensor")
                    }
                )
            }

            if store.state.isConnectionPaired {
                if store.state.isConnectable {
                    Button(
                        action: {
                            withAnimation {
                                store.dispatch(.connectConnection)
                            }
                        },
                        label: {
                            if store.state.isTransmitter {
                                Text("Connect transmitter")
                            } else {
                                Text("Connect sensor")
                            }
                        }
                    )
                } else if store.state.isDisconnectable {
                    Button(
                        action: {
                            showingDisconnectConnectionAlert = true
                        },
                        label: {
                            if store.state.isTransmitter {
                                Text("Disconnect transmitter")
                            } else {
                                Text("Disconnect sensor")
                            }
                        }
                    ).alert(isPresented: $showingDisconnectConnectionAlert) {
                        Alert(
                            title: Text("Are you sure you want to disconnect the sensor?"),
                            primaryButton: .destructive(Text("Disconnect")) {
                                withAnimation {
                                    store.dispatch(.disconnectConnection)
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
        }
    }

    // MARK: Private

    @State private var showingDisconnectConnectionAlert = false
}
