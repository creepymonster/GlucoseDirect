//
//  SensorNFCView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct InternalsView: View {
    var sensor: Sensor?

    var body: some View {
        if let sensor = sensor {
            GroupBox(label: Text("SENSOR INTERNALS")) {
                KeyValueView(key: "UID", value: sensor.uuid.hex)
                KeyValueView(key: "PatchInfo", value: sensor.patchInfo.hex)
                KeyValueView(key: "Serial", value: sensor.serial?.description ?? "Unknown")
                KeyValueView(key: "Calibration", value: sensor.calibration.description)
            }
        }
    }
}
