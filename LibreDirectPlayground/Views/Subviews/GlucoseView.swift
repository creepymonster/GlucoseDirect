//
//  SensorGlucoseView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct GlucoseView: View {
    var trendValues: [SensorGlucose]

    var body: some View {
        if trendValues.count > 0 {
            Divider().padding(.trailing)

            Section(header: HStack {
                Text("GLUCOSE").foregroundColor(.gray).font(.subheadline)
                Spacer()
            }) {
                ForEach(trendValues, id: \.id) { glucose in
                    GlucoseDetailsView(glucose: glucose)
                }
            }
        }
    }
}

struct GlucoseDetailsView: View {
    var glucose: SensorGlucose
    
    var body: some View {
        KeyValueView(key: glucose.timeStamp.localTime, value: "\(glucose.glucoseFiltered.description) \(glucose.trend.description)")
    }
    
    init(glucose: SensorGlucose) {
        self.glucose = glucose
    }
}
