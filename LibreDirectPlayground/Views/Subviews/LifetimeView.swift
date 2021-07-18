//
//  SensorLife.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct LifetimeView: View {
    var sensor: Sensor?

    var body: some View {
        if let sensor = sensor {
            Divider().padding(.trailing)

            Section(header: HStack {
                Text("SENSOR LIFETIME").foregroundColor(.gray).font(.subheadline)
                Spacer()
            }) {
                KeyValueView(key: "State", value: sensor.state.description)
                KeyValueView(key: "Lifetime", value: sensor.lifetime.inTime)

                if let age = sensor.age {
                    KeyValueView(key: "Age", value: age.inTime)
                }

                if let remainingLifetime = sensor.remainingLifetime {
                    KeyValueView(key: "Remaining", value: remainingLifetime.inTime)
                }
            }
        }
    }
}
