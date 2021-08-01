//
//  SensorLife.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 06.07.21.
//

import SwiftUI

struct LifetimeView: View {
    var sensor: Sensor?

    var body: some View {
        if let sensor = sensor {
            GroupBox(label: Text("Sensor Lifetime").padding(.bottom).foregroundColor(.accentColor)) {
                KeyValueView(key: LocalizedString("Sensor State", comment: ""), value: sensor.state.description)
                
                HStack(alignment: .center, spacing: 0) {
                    VStack {
                        KeyValueView(key: LocalizedString("Sensor Possible Lifetime", comment: ""), value: sensor.lifetime.inTime).padding(.top, 5)

                        if let age = sensor.age {
                            KeyValueView(key: LocalizedString("Sensor Age", comment: ""), value: age.inTime).padding(.top, 5)
                        }

                        if let remainingLifetime = sensor.remainingLifetime {
                            KeyValueView(key: LocalizedString("Sensor Remaining Lifetime", comment: ""), value: remainingLifetime.inTime).padding(.top, 5)
                        }
                    }
                }
            }
        }
    }
}

struct LifetimeView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            LifetimeView(sensor: previewSensor).preferredColorScheme($0)
        }
    }
}
