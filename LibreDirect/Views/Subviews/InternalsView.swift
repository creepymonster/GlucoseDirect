//
//  InternalsView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI
import LibreDirectLibrary

struct InternalsView: View {
    var sensor: Sensor?

    var body: some View {
        if let sensor = sensor {
            GroupBox(label: Text("Sensor Internals").padding(.bottom).foregroundColor(.accentColor)) {
                KeyValueView(key: LocalizedString("Sensor UID", comment: ""), value: sensor.uuid.hex)
                KeyValueView(key: LocalizedString("Sensor PatchInfo", comment: ""), value: sensor.patchInfo.hex).padding(.top, 5)
                KeyValueView(key: LocalizedString("Sensor Serial", comment: ""), value: sensor.serial?.description ?? "Unknown").padding(.top, 5)
                KeyValueView(key: LocalizedString("Sensor Calibration", comment: ""), value: sensor.calibration.description).padding(.top, 5)
            }
        }
    }
}

struct InternalsView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            InternalsView(sensor: previewSensor).preferredColorScheme($0)
        }
    }
}
