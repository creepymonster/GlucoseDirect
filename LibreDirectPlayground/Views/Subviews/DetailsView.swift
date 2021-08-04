//
//  DetailsView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct DetailsView: View {
    var sensor: Sensor?

    var body: some View {
        if let sensor = sensor {
            GroupBox(label: Text("Sensor Details").padding(.bottom).foregroundColor(.accentColor)) {
                KeyValueView(key: LocalizedString("Sensor Region", comment: ""), value: sensor.region.description)
                KeyValueView(key: LocalizedString("Sensor Type", comment: ""), value: sensor.type.description).padding(.top, 5)
            }
        }
    }
}

struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            DetailsView(sensor: previewSensor).preferredColorScheme($0)
        }
    }
}
