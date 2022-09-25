//
//  SensorConfiguration.swift
//  GlucoseDirectApp
//

import SwiftUI

struct SensorConnectionConfigurationView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore
    
    var body: some View {
        if let selectedConnection = store.state.selectedConnection, let configuration = selectedConnection.getConfiguration() {
            Section(
                content: {
                    ForEach(configuration, id: \.id) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.name)
                            
                            if entry.isSecret {
                                SecureField("", text: entry.value)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else {
                                TextField("", text: entry.value)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

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
