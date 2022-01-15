//
//  SensorConnectorSettings.swift
//  LibreDirect
//

import SwiftUI

// MARK: - SensorConnectorSettings

struct SensorConnectorSettings: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
        if store.state.connectionInfos.count > 1 {
            Section(
                content: {
                    HStack {
                        Text("Transmitter")
                        Spacer()

                        Picker("", selection: selectedConnectionId) {
                            ForEach(store.state.connectionInfos, id: \.id) { info in
                                Text(info.name)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    
                    HStack {
                        Text("Retrieval interval")
                        Spacer()

                        Picker("", selection: selectedSensorInterval) {
                            ForEach([1, 5], id: \.self) { interval in
                                Text("Retrieval interval, \(interval) minutes")
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

    // MARK: Private

    private var selectedConnectionId: Binding<String> {
        Binding(
            get: { store.state.selectedConnectionId ?? "" },
            set: { store.dispatch(.selectConnectionId(id: $0)) }
        )
    }
    
    private var selectedSensorInterval: Binding<Int> {
        Binding(
            get: { store.state.sensorInterval },
            set: { store.dispatch(.setSensorInterval(interval: $0)) }
        )
    }
}

// MARK: - SensorConnectorSettings_Previews

struct SensorConnectorSettings_Previews: PreviewProvider {
    static var previews: some View {
        SensorConnectorSettings()
    }
}
