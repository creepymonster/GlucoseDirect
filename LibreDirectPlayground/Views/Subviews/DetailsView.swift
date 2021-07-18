//
//  SensorContentView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct DetailsView: View {
    var sensor: Sensor?

    var body: some View {
        if let sensor = sensor {
            Divider().padding(.trailing)

            Section(header: HStack {
                Text("SENSOR DETAILS").foregroundColor(.gray).font(.subheadline)
                Spacer()
            }) {
                KeyValueView(key: "Region", value: sensor.region.description)
                KeyValueView(key: "Type", value: sensor.type.description)
            }
        }
    }
}
