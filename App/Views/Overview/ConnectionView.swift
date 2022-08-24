//
//  ConnectionView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ConnectionView

struct ConnectionView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        Section(
            content: {
                if store.state.isConnectionPaired {
                    HStack {
                        Text("Connection state")
                        Spacer()
                        Text(store.state.connectionState.localizedDescription)
                    }
                }

                if let connectionError = store.state.connectionError,
                   let connectionErrorTimestamp = store.state.connectionErrorTimestamp?.toLocalTime()
                {
                    HStack {
                        Text("Connection error")
                        Spacer()
                        Text(connectionError)
                    }

                    HStack {
                        Text("Connection error timestamp")
                        Spacer()
                        Text(connectionErrorTimestamp)
                    }
                }

                ActionsView()
            },
            header: {
                Label("Connection", systemImage: "rectangle.connected.to.line.below")
            }
        )
    }
}
