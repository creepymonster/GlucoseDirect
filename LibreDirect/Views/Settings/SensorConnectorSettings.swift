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

                        Picker("", selection: selectedConnectionID) {
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
                            ForEach([1, 5, 15], id: \.self) { interval in
                                if interval == 1 {
                                    Text("Retrieval interval, every minute")
                                } else {
                                    Text(String(format: LocalizedString("Retrieval interval, every %1$@ minutes"), interval.description))
                                }
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

    private var selectedConnectionID: Binding<String> {
        Binding(
            get: { store.state.selectedConnectionID ?? "" },
            set: { store.dispatch(.selectConnectionID(id: $0)) }
        )
    }

    private var selectedSensorInterval: Binding<Int> {
        Binding(
            get: { store.state.sensorInterval },
            set: { store.dispatch(.setSensorInterval(interval: $0)) }
        )
    }
}
