//
//  LifetimeView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI
import LibreDirectLibrary

struct LifetimeView: View {
    var sensor: Sensor?
    
    var startAngle: Double {
        get {
            return 360
        }
    }
    
    var remainingEndAngle: Double? {
        get {
            if let sensor = sensor, let remainingLifetime = sensor.remainingLifetime {
                let angle = (360.0 / Double(sensor.lifetime)) * Double(remainingLifetime)
                return angle
            }
            
            return nil
        }
    }
    
    var elapsedEndAngle: Double? {
        get {
            if let sensor = sensor, let elapsedLifetime = sensor.elapsedLifetime {
                let angle = (360.0 / Double(sensor.lifetime)) * Double(elapsedLifetime)
                return angle
            }
            
            return nil
        }
    }

    var body: some View {
        if let sensor = sensor {
            GroupBox(label: Text("Sensor Lifetime").padding(.bottom).foregroundColor(.accentColor)) {
                KeyValueView(key: LocalizedBundleString("Sensor State", comment: ""), value: sensor.state.description)
                
                HStack(alignment: .center, spacing: 0) {
                    VStack {
                        KeyValueView(key: LocalizedBundleString("Sensor Possible Lifetime", comment: ""), value: sensor.lifetime.inTime).padding(.top, 5)

                        if let age = sensor.age {
                            KeyValueView(key: LocalizedBundleString("Sensor Age", comment: ""), value: age.inTime, valueColor: Color.accentColor).padding(.top, 5)
                        }

                        if let remainingLifetime = sensor.remainingLifetime {
                            KeyValueView(key: LocalizedBundleString("Sensor Remaining Lifetime", comment: ""), value: remainingLifetime.inTime).padding(.top, 5)
                        }
                    }
                    
                    if let endAngle = elapsedEndAngle {
                        ZStack {
                            GeometryReader { geo in
                                Circle()
                                    .fill(Color.white)
                                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                    .frame(width: geo.size.width, height: geo.size.width)
                                
                                Path { path in
                                    path.move(to: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                                    path.addArc(center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2), radius: geo.size.width / 2, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: false)
                                }
                                .rotation(.degrees(-90))
                                .fill(Color.accentColor)
                            }
                        }.frame(width: 50, height: 50)
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
