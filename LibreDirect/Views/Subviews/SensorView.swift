//
//  DetailsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - SensorView

struct SensorView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    @Environment(\.colorScheme) var colorScheme

    @State var deviceColorScheme = ColorScheme.light

    var batteryEndAngle: Double? {
        if let transmitter = store.state.transmitter {
            let angle = 3.6 * Double(transmitter.battery)
            return angle
        }

        return nil
    }

    var remainingWarmupEndAngle: Double? {
        if let sensor = store.state.sensor, let remainingWarmupTime = sensor.remainingWarmupTime {
            let angle = (360.0 / Double(sensor.warmupTime)) * Double(remainingWarmupTime)
            return angle
        }

        return nil
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
        Group {
            if store.state.isPaired {
                Section(
                    content: {
                        HStack {
                            Text("Connection state")
                            Spacer()
                            Text(store.state.connectionState.localizedString).textSelection(.enabled)
                        }

                        if store.state.missedReadings > 0 {
                            HStack {
                                Text("Missed readings")
                                Spacer()
                                Text(store.state.missedReadings.description).textSelection(.enabled)
                            }
                        }

                        if let connectionError = store.state.connectionError {
                            HStack {
                                Text("Connection error")
                                Spacer()
                                Text(connectionError).textSelection(.enabled)
                            }
                        }

                        if let connectionErrorTimestamp = store.state.connectionErrorTimestamp?.localTime {
                            HStack {
                                Text("Connection error timestamp")
                                Spacer()
                                Text(connectionErrorTimestamp).textSelection(.enabled)
                            }
                        }
                    },
                    header: {
                        Label("Connection", systemImage: "rectangle.connected.to.line.below")
                    }
                )
            }

            if let transmitter = store.state.transmitter {
                Section(
                    content: {
                        HStack {
                            Text("Transmitter name")
                            Spacer()
                            Text(transmitter.name).textSelection(.enabled)
                        }

                        HStack {
                            Text("Transmitter battery")
                            Spacer()
                            Text(transmitter.battery.description).textSelection(.enabled)

                            if let endAngle = batteryEndAngle {
                                ZStack {
                                    GeometryReader { geo in
                                        Circle()
                                            .fill(Config.color)
                                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                            .frame(width: geo.size.width, height: geo.size.width)

                                        Path { path in
                                            path.move(to: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                                            path.addArc(center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2), radius: geo.size.width / 2, startAngle: .degrees(0), endAngle: .degrees(endAngle), clockwise: false)
                                        }
                                        .rotation(.degrees(-90))
                                        .fill(Color.accentColor)
                                    }
                                }.frame(width: Config.size, height: Config.size)
                            }
                        }

                        if let hardware = transmitter.hardware {
                            HStack {
                                Text("Transmitter hardware")
                                Spacer()
                                Text(hardware.description).textSelection(.enabled)
                            }
                        }

                        if let firmware = transmitter.firmware {
                            HStack {
                                Text("Transmitter firmware")
                                Spacer()
                                Text(firmware.description).textSelection(.enabled)
                            }
                        }
                    },
                    header: {
                        Label("Transmitter Details", systemImage: "antenna.radiowaves.left.and.right.circle")
                    }
                )
            }

            if let sensor = store.state.sensor {
                Section(
                    content: {
                        HStack {
                            Text("Sensor type")
                            Spacer()
                            Text(sensor.type.localizedString).textSelection(.enabled)
                        }

                        HStack {
                            Text("Sensor region")
                            Spacer()
                            Text(sensor.region.localizedString).textSelection(.enabled)
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
                                Text("Sensor serial")
                                Spacer()
                                Text(serial.description).textSelection(.enabled)
                            }
                        }
                    },
                    header: {
                        Label("Sensor details", systemImage: "text.magnifyingglass")
                    }
                )

                Section(
                    content: {
                        HStack {
                            Text("Sensor state")
                            Spacer()
                            Text(sensor.state.localizedString).textSelection(.enabled)
                        }

                        if let startTimestamp = sensor.startTimestamp {
                            HStack {
                                Text("Sensor starting date")
                                Spacer()
                                Text(startTimestamp.localDateTime)
                            }
                        }

                        if let remainingWarmupTime = sensor.remainingWarmupTime, sensor.state == .starting {
                            HStack {
                                Text("Sensor remaining warmup time")
                                Spacer()
                                Text(remainingWarmupTime.inTime).textSelection(.enabled)

                                if let endAngle = remainingWarmupEndAngle {
                                    ZStack {
                                        GeometryReader { geo in
                                            Circle()
                                                .fill(Config.color)
                                                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                                .frame(width: geo.size.width, height: geo.size.width)

                                            Path { path in
                                                path.move(to: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                                                path.addArc(center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2), radius: geo.size.width / 2, startAngle: .degrees(0), endAngle: .degrees(endAngle), clockwise: false)
                                            }
                                            .rotation(.degrees(-90))
                                            .fill(Color.accentColor)
                                        }
                                    }.frame(width: Config.size, height: Config.size)
                                }
                            }
                        } else if sensor.state != .expired && sensor.state != .shutdown && sensor.state != .unknown {
                            HStack {
                                Text("Sensor possible lifetime")
                                Spacer()
                                Text(sensor.lifetime.inTime).textSelection(.enabled)
                            }

                            HStack {
                                Text("Sensor age")
                                Spacer()
                                Text(sensor.age.inTime).textSelection(.enabled)

                                if let endAngle = elapsedEndAngle {
                                    ZStack {
                                        GeometryReader { geo in
                                            Circle()
                                                .fill(Config.color)
                                                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                                .frame(width: geo.size.width, height: geo.size.width)

                                            Path { path in
                                                path.move(to: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                                                path.addArc(center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2), radius: geo.size.width / 2, startAngle: .degrees(360), endAngle: .degrees(endAngle), clockwise: false)
                                            }
                                            .rotation(.degrees(-90))
                                            .fill(Color.accentColor)
                                        }
                                    }.frame(width: Config.size, height: Config.size)
                                }
                            }

                            if let remainingLifetime = sensor.remainingLifetime {
                                HStack {
                                    Text("Sensor remaining lifetime")
                                    Spacer()
                                    Text(remainingLifetime.inTime).textSelection(.enabled)

                                    if let endAngle = remainingEndAngle {
                                        ZStack {
                                            GeometryReader { geo in
                                                Circle()
                                                    .fill(Config.color)
                                                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                                    .frame(width: geo.size.width, height: geo.size.width)

                                                Path { path in
                                                    path.move(to: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                                                    path.addArc(center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2), radius: geo.size.width / 2, startAngle: .degrees(360), endAngle: .degrees(endAngle), clockwise: false)
                                                }
                                                .rotation(.degrees(-90))
                                                .fill(Color.accentColor)
                                            }
                                        }.frame(width: Config.size, height: Config.size)
                                    }
                                }
                            }
                        }
                    },
                    header: {
                        Label("Sensor lifetime", systemImage: "timer")
                    }
                )
            }
        }.onChange(of: colorScheme) { scheme in
            if deviceColorScheme != scheme {
                AppLog.info("onChange colorScheme: \(scheme)")

                deviceColorScheme = scheme
            }
        }
    }

    // MARK: Private

    private enum Config {
        static let size: CGFloat = 20

        static var color: Color { Color(hex: "#E4E6EB") | Color(hex: "#404040") }
    }
}

// MARK: - SensorView_Previews

struct SensorView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            SensorView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
