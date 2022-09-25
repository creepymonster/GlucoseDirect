//
//  SensorConfiguration.swift
//  GlucoseDirectApp
//

import SwiftUI

struct SensorConnectionConfigurationView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore
    
    var body: some View {
        if let connectorConfiguration = store.state.selectedConnection as? SensorConnectionConfigurationProtocol, let configuration = connectorConfiguration.getConfiguration() {
            Section(
                content: {
                    ForEach(configuration, id: \.id) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.name)
                            TextField("", text: entry.value)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                },
                header: {
                    Label("Connection settings", systemImage: "app.connected.to.app.below.fill")
                }
            )
        }
    }
}
