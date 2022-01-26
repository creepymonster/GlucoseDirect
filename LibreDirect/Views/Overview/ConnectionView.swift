//
//  ConnectionView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - ConnectionView

struct ConnectionView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                if store.state.isPaired {
                    HStack {
                        Text("Connection state")
                        Spacer()
                        Text(store.state.connectionState.localizedString)
                    }

                    if store.state.missedReadings > 0 {
                        HStack {
                            Text("Missed readings")
                            Spacer()
                            Text(store.state.missedReadings.description)
                        }
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
