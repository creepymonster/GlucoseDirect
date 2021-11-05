//
//  DetailsView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

// MARK: - DetailsView

struct DetailsView: View {
    var sensor: Sensor?

    var body: some View {
        if let sensor = sensor {
            GroupBox(label: Text("Sensor Details").padding(.bottom).foregroundColor(.accentColor)) {
                KeyValueView(key: LocalizedString("Sensor Region", comment: ""), value: sensor.region.description)
                KeyValueView(key: LocalizedString("Sensor Type", comment: ""), value: sensor.type.description).padding(.top, 5)
            }

            GroupBox(label: Text("Sensor Internals").padding(.bottom).foregroundColor(.accentColor)) {
                KeyValueView(key: LocalizedString("Sensor UID", comment: ""), value: sensor.uuid.hex)
                KeyValueView(key: LocalizedString("Sensor PatchInfo", comment: ""), value: sensor.patchInfo.hex).padding(.top, 5)
                KeyValueView(key: LocalizedString("Sensor Serial", comment: ""), value: sensor.serial?.description ?? "Unknown").padding(.top, 5)
                KeyValueView(key: LocalizedString("Sensor Factory Calibration", comment: ""), value: sensor.factoryCalibration.description).padding(.top, 5)
            }
        }
    }
}

// MARK: - DetailsView_Previews

struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            DetailsView(sensor: previewSensor).preferredColorScheme($0)
        }
    }
}
