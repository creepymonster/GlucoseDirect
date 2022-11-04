//
//  SensorConnectorSettings.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - SensorConnectorSettings

struct SensorConnectorSettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        if store.state.connectionInfos.count > 1 {
            Section(
                content: {
                    Picker("Transmitter", selection: selectedConnectionID) {
                        ForEach(store.state.connectionInfos, id: \.id) { info in
                            Text(info.name)
                                .lineLimit(1)
                        }
                    }.pickerStyle(.menu)

                    Picker("Retrieval interval", selection: selectedSensorInterval) {
                        ForEach(intervals, id: \.self) { interval in
                            if interval == 1 {
                                Text("Retrieval interval, every minute")
                                    .lineLimit(1)
                            } else {
                                Text("Retrieval interval, every \(interval.description) minutes")
                                    .lineLimit(1)
                            }
                        }
                    }.pickerStyle(.menu)
                },
                header: {
                    Label("Sensor connection", systemImage: "app.connected.to.app.below.fill")
                }
            )
        }
    }

    // MARK: Private

    private let intervals: [Int] = [1, 5, 15]

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
