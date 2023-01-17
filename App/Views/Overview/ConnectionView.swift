//
//  ConnectionView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ConnectionView

struct ConnectionView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        if let connectionError = store.state.connectionError, let connectionErrorTimestamp = store.state.connectionErrorTimestamp?.toLocalTime() {
            Section(
                content: {
                    Link(connectionError, destination: URL(string: DirectConfig.faqURL)!)
                        .foregroundColor(Color.ui.red)

                    HStack {
                        Text("Connection error timestamp")
                        Spacer()
                        Text(connectionErrorTimestamp)
                    }

                    HStack {
                        Text("Help")
                        Spacer()
                        Link("App faq", destination: URL(string: DirectConfig.faqURL)!)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }
                },
                header: {
                    Label("Connection error", systemImage: "exclamationmark.triangle")
                        .foregroundColor(Color.ui.red)
                }
            )
        }

        Section(
            content: {
                if store.state.isConnectionPaired {
                    HStack {
                        Text("Connection state")
                        Spacer()
                        Text(store.state.connectionState.localizedDescription)
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
            },
            header: {
                Label("Sensor connection", systemImage: "rectangle.connected.to.line.below")
            }
        )
    }

    // MARK: Private

    @State private var showingDisconnectConnectionAlert = false
}
