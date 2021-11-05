//
//  ActionsView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct ActionsView: View {
    @State private var showingDeleteLogsAlert = false
    @State private var showingDisconnectSensorAlert = false
    @State private var showingUnpairSensorAlert = false

    @EnvironmentObject var store: AppStore

    var body: some View {
        if store.state.isPaired && store.state.isConnectable {
            Button(action: { store.dispatch(.connectSensor) }) {
                Label("Connect Sensor", systemImage: "play")
            }

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

        if store.state.isPaired && store.state.isDisconnectable {
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

        if store.state.isPairable {
            Button(action: { store.dispatch(.pairSensor) }) {
                Label("Pair Sensor", systemImage: "arrow.uturn.forward")
            }
        }

        /* Button(
             action: { showingDeleteLogsAlert = true },
             label: { Label("Delete Logs", systemImage: "trash") }
         ).alert(isPresented: $showingDeleteLogsAlert) {
             Alert(
                 title: Text("Are you sure you want to delete the log files?"),
                 primaryButton: .destructive(Text("Delete")) {
                     Log.clear()
                 },
                 secondaryButton: .cancel()
             )
         } */
    }
}
