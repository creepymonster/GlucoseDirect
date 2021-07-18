//
//  ActionsView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct ActionsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Divider().padding(.trailing)
        
        if store.state.isPaired && store.state.isConnectable {
            Button(action: { store.dispatch(.connectSensor) }) {
                Label("Connect", systemImage: "play")
            }

            Button(action: { store.dispatch(.resetSensor) }) {
                Label("Unpair", systemImage: "arrow.uturn.backward")
            }
        }

        if store.state.isPaired && store.state.isDisconnectable {
            Button(action: { store.dispatch(.disconnectSensor) }) {
                Label("Disconnect", systemImage: "stop")
            }
        }

        if store.state.isPairable {
            Button(action: { store.dispatch(.pairSensor) }) {
                Label("Pair", systemImage: "arrow.uturn.forward")
            }
        }
    }
}
