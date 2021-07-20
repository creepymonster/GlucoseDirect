//
//  SensorConnectionView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct ConnectionView: View {
    var connectionState: SensorConnectionState
    var connectionError: String?

    var body: some View {
        GroupBox(label: Text("CONNECTION")) {
            KeyValueView(key: "State", value: connectionState.description)

            if let connectionError = connectionError {
                KeyValueView(key: "Error", value: connectionError)
            }
        }
    }
}
