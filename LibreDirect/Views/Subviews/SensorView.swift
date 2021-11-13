//
//  DetailsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - DetailsView

struct SensorView: View {
    @EnvironmentObject var store: AppStore

    var startAngle: Double {
        return 360
    }
    
    var remainingEndAngle: Double? {
        if let sensor = store.state.sensor, let remainingLifetime = sensor.remainingLifetime {
            let angle = (360.0 / Double(sensor.lifetime)) * Double(remainingLifetime)
            return angle
        }
            
        return nil
    }
    
    var elapsedEndAngle: Double? {
        if let sensor = store.state.sensor, let elapsedLifetime = sensor.elapsedLifetime {
            let angle = (360.0 / Double(sensor.lifetime)) * Double(elapsedLifetime)
            return angle
        }
            
        return nil
    }

    var body: some View {
        ListView(header: "Sensor Connection", rows: [
            ListViewRow(key: "Sensor Connection State", value: store.state.connectionState.localizedString),
            ListViewRow(key: "Sensor Missed Readings", value: store.state.missedReadings.description, isVisible: store.state.missedReadings > 0),
            ListViewRow(key: "Sensor Connection Error", value: store.state.connectionError),
            ListViewRow(key: "Sensor Connection Error Timestamp", value: store.state.connectionErrorTimestamp?.localTime),
        ])
        
        ListView(header: "Sensor Details", rows: [
            ListViewRow(key: "Sensor Region", value: store.state.sensor?.region.localizedString),
            ListViewRow(key: "Sensor Type", value: store.state.sensor?.type.localizedString),
            ListViewRow(key: "Sensor UID", value: store.state.sensor?.uuid.hex),
            ListViewRow(key: "Sensor PatchInfo", value: store.state.sensor?.patchInfo.hex),
            ListViewRow(key: "Sensor Serial", value: store.state.sensor?.serial?.description),
        ])
        
        ListView(header: "Sensor Lifetime", rows: [
            ListViewRow(key: "Sensor State", value: store.state.sensor?.state.localizedString),
            ListViewRow(key: "Sensor Possible Lifetime", value: store.state.sensor?.lifetime.inTime),
            ListViewRow(key: "Sensor Age", value: store.state.sensor?.age.inTime),
            ListViewRow(key: "Sensor Remaining Lifetime", value: store.state.sensor?.remainingLifetime?.inTime),
        ])
    }
}
