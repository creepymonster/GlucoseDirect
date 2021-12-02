//
//  SensorConnectorSettings.swift
//  LibreDirect
//

import SwiftUI

struct SensorConnectorSettings: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        if store.state.connectionInfos.count > 1 {
            Section(
                content: {
                    HStack {
                        Text("Sensor connection type")
                        Spacer()

                        Picker("Connection", selection: selectedConnectionId) {
                            ForEach(store.state.connectionInfos, id: \.id) { info in
                                Text(info.name)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                },
                header: {
                    Label("Sensor connection", systemImage: "app.connected.to.app.below.fill")
                }
            )
        }
    }
    
    private var selectedConnectionId: Binding<String> {
        Binding(
            get: { store.state.selectedConnectionId ?? "" },
            set: { store.dispatch(.selectedConnectionId(id: $0)) }
        )
    }
}

struct SensorConnectorSettings_Previews: PreviewProvider {
    static var previews: some View {
        SensorConnectorSettings()
    }
}
