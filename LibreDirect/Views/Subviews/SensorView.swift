//
//  DetailsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - SensorView

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
        if let sensor = store.state.sensor {
            Section(
                content: {
                    HStack {
                        Text("Sensor Connection State")
                        Spacer()
                        Text(store.state.connectionState.localizedString).textSelection(.enabled)
                    }
                
                    if store.state.missedReadings > 0 {
                        HStack {
                            Text("Sensor Missed Readings")
                            Spacer()
                            Text(store.state.missedReadings.description).textSelection(.enabled)
                        }
                    }
                
                    if let connectionError = store.state.connectionError {
                        HStack {
                            Text("Sensor Connection Error")
                            Spacer()
                            Text(connectionError).textSelection(.enabled)
                        }
                    }
                
                    if let connectionErrorTimestamp = store.state.connectionErrorTimestamp?.localTime {
                        HStack {
                            Text("Sensor Connection Error Timestamp")
                            Spacer()
                            Text(connectionErrorTimestamp).textSelection(.enabled)
                        }
                    }
                },
                header: {
                    Label("Sensor Connection", systemImage: "rectangle.connected.to.line.below")
                }
            )
        
            Section(
                content: {
                    HStack {
                        Text("Sensor Region")
                        Spacer()
                        Text(sensor.region.localizedString).textSelection(.enabled)
                    }
                    
                    HStack {
                        Text("Sensor Type")
                        Spacer()
                        Text(sensor.type.localizedString).textSelection(.enabled)
                    }
                    
                    HStack {
                        Text("Sensor UID")
                        Spacer()
                        Text(sensor.uuid.hex).textSelection(.enabled)
                    }
                    
                    HStack {
                        Text("Sensor PatchInfo")
                        Spacer()
                        Text(sensor.patchInfo.hex).textSelection(.enabled)
                    }
                    
                    if let serial = sensor.serial {
                        HStack {
                            Text("Sensor Serial")
                            Spacer()
                            Text(serial.description).textSelection(.enabled)
                        }
                    }
                },
                header: {
                    Label("Sensor Details", systemImage: "text.magnifyingglass")
                }
            )
            
            Section(
                content: {
                    HStack {
                        Text("Sensor State")
                        Spacer()
                        Text(sensor.state.localizedString).textSelection(.enabled)
                    }
                    
                    if let remainingWarmupTime = sensor.remainingWarmupTime {
                        HStack {
                            Text("Sensor Remaining Warmup time")
                            Spacer()
                            Text(remainingWarmupTime.inTime).textSelection(.enabled)
                        }
                    } else {
                        HStack {
                            Text("Sensor Possible Lifetime")
                            Spacer()
                            Text(sensor.lifetime.inTime).textSelection(.enabled)
                        }
                    
                        HStack {
                            Text("Sensor Age")
                            Spacer()
                            Text(sensor.age.inTime).textSelection(.enabled)
                        }
                        
                        if let remainingLifetime = sensor.remainingLifetime {
                            HStack {
                                Text("Sensor Remaining Lifetime")
                                Spacer()
                                Text(remainingLifetime.inTime).textSelection(.enabled)
                            }
                        }
                    }
                },
                header: {
                    Label("Sensor Lifetime", systemImage: "timer")
                }
            )
        }
    }
}
