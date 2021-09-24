//
//  ConnectionView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI
import LibreDirectLibrary

struct ConnectionView: View {
    var connectionState: SensorConnectionState
    var connectionError: String?
    var connectionErrorTimestamp: Date?
    var missedReadings: Int

    var body: some View {
        GroupBox(label: Text("Sensor Connection").padding(.bottom).foregroundColor(.accentColor)) {
            KeyValueView(key: LocalizedString("Sensor Connection State", comment: ""), value: connectionState.description)

            if missedReadings > 0 {
                KeyValueView(key: LocalizedString("Sensor Missed Readings", comment: ""), value: missedReadings.description).padding(.top, 5)
            }

            if let connectionError = connectionError {
                KeyValueView(key: LocalizedString("Sensor Connection Error", comment: ""), value: connectionError).padding(.top, 5)
            }

            if let connectionErrorTimestamp = connectionErrorTimestamp {
                KeyValueView(key: LocalizedString("Sensor Connection Error Timestamp", comment: ""), value: connectionErrorTimestamp.localTime).padding(.top, 5)
            }
        }
    }
}

struct ConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            ConnectionView(connectionState: .connected, missedReadings: 0).preferredColorScheme($0)
            ConnectionView(connectionState: .disconnected, connectionError: "Timeout", connectionErrorTimestamp: Date(), missedReadings: 5).preferredColorScheme($0)
        }
    }
}
