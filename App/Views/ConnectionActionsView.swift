//
//  ActionsView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ActionsView

struct ConnectionActionsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        if store.state.isConnectionPaired {
            HStack {
                Text("Connection state")
                Spacer()
                Text(store.state.connectionState.localizedDescription)
            }
        }

        if let connectionError = store.state.connectionError, let connectionErrorTimestamp = store.state.connectionErrorTimestamp?.toLocalTime() {
            VStack(alignment: .leading) {
                Text("Connection error")
                Text(connectionError)
            }

            HStack {
                Text("Connection error timestamp")
                Spacer()
                Text(connectionErrorTimestamp)
            }
        }

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
                ).disabled(store.state.connectionIsBusy)
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
