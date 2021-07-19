//
//  SensorGlucoseView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct GlucoseView: View {
    var glucose: SensorGlucose?

    var body: some View {
        if let glucose = glucose {
            Divider().padding(.trailing)

            VStack {
                Text("\(glucose.trend.description)")
                Text("\(glucose.glucoseFiltered.description)").font(.system(size: 60))
                Text("\(glucose.timeStamp.localTime)")
            }
        }
    }
}

struct GlucoseView_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseView(glucose: SensorGlucose(id: 1, timeStamp: Date(), glucose: 100, trend: .constant))
    }
}
