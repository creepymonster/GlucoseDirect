//
//  ActionsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - ActionsView

struct ActionsView: View {
    @State private var showingDeleteLogsAlert = false
    @State private var showingDisconnectSensorAlert = false
    @State private var showingUnpairSensorAlert = false

    @EnvironmentObject var store: AppStore

    var body: some View {
        HStack {
            if store.state.isPaired {
                if !store.state.isDisconnectable {
                    Button(
                        action: { showingUnpairSensorAlert = true },
                        label: { Label("Unpair Sensor", systemImage: "arrow.uturn.backward") }
                    ).alert(isPresented: $showingUnpairSensorAlert) {
                        Alert(
                            title: Text("Are you sure you want to unpair the sensor?"),
                            primaryButton: .destructive(Text("Unpair")) {
                                store.dispatch(.resetSensor)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }

                if store.state.isConnectable {
                    Spacer()

                    Button(action: { store.dispatch(.connectSensor) }) {
                        Label("Connect Sensor", systemImage: "play")
                    }
                } else if store.state.isDisconnectable {
                    Button(
                        action: { showingDisconnectSensorAlert = true },
                        label: { Label("Disconnect Sensor", systemImage: "stop") }
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
            } else {
                Button(action: { store.dispatch(.pairSensor) }) {
                    Label("Pair Sensor", systemImage: "arrow.uturn.forward")
                }
            }
        }.padding([.top, .horizontal])
    }
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
