//
//  DetailsView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - SensorView

struct SensorView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            if let sensor = store.state.sensor {
                Section(
                    content: {
                        HStack {
                            Text("Sensor state")
                            Spacer()
                            Text(sensor.state.localizedString)
                        }

                        if sensor.state == .notYetStarted {
                            HStack {
                                Image(systemName: "hand.raised.square")

                                Text("Use LibreLink to start the sensor")
                                    .bold()
                            }
                            .foregroundColor(Color.ui.red)
                        } else {
                            if let startTimestamp = sensor.startTimestamp {
                                HStack {
                                    Text("Sensor starting date")
                                    Spacer()
                                    Text(startTimestamp.toLocalDateTime())
                                }
                            }

                            if let remainingWarmupTime = sensor.remainingWarmupTime, sensor.state == .starting {
                                VStack {
                                    HStack {
                                        Text("Sensor remaining warmup time")
                                        Spacer()
                                        Text(remainingWarmupTime.inTime)
                                    }

                                    ProgressView("", value: remainingWarmupTime.inPercent(of: sensor.warmupTime), total: 100)
                                }

                            } else if sensor.state != .expired && sensor.state != .shutdown && sensor.state != .unknown {
                                HStack {
                                    Text("Sensor possible lifetime")
                                    Spacer()
                                    Text(sensor.lifetime.inTime)
                                }

                                VStack {
                                    HStack {
                                        Text("Sensor age")
                                        Spacer()
                                        Text(sensor.age.inTime)
                                    }

                                    ProgressView("", value: sensor.age.inPercent(of: sensor.lifetime), total: 100)
                                }

                                VStack {
                                    HStack {
                                        Text("Sensor remaining lifetime")
                                        Spacer()
                                        Text(sensor.remainingLifetime.inTime)
                                    }

                                    ProgressView("", value: sensor.remainingLifetime.inPercent(of: sensor.lifetime), total: 100)
                                }
                            }
                        }
                    },
                    header: {
                        Label("Sensor lifetime", systemImage: "timer")
                    }
                )
            }

            if let sensor = store.state.sensor {
                Section(
                    content: {
                        HStack {
                            Text("Sensor type")
                            Spacer()
                            Text(sensor.type.localizedString)
                        }

                        HStack {
                            Text("Sensor region")
                            Spacer()
                            Text(sensor.region.localizedString)
                        }

                        HStack {
                            Text("Sensor UID")
                            Spacer()
                            Text(sensor.uuid.hex)
                        }

                        HStack {
                            Text("Sensor PatchInfo")
                            Spacer()
                            Text(sensor.patchInfo.hex)
                        }

                        if let serial = sensor.serial {
                            HStack {
                                Text("Sensor serial")
                                Spacer()
                                Text(serial.description)
                            }
                        }
                    },
                    header: {
                        Label("Sensor details", systemImage: "text.magnifyingglass")
                    }
                )
            }

            if let transmitter = store.state.transmitter {
                Section(
                    content: {
                        HStack {
                            Text("Transmitter name")
                            Spacer()
                            Text(transmitter.name)
                        }

                        VStack {
                            HStack {
                                Text("Transmitter battery")
                                Spacer()
                                Text("\(transmitter.battery)%")
                            }

                            ProgressView("", value: Double(transmitter.battery), total: 100)
                        }

                        if let hardware = transmitter.hardware {
                            HStack {
                                Text("Transmitter hardware")
                                Spacer()
                                Text(hardware.description)
                            }
                        }

                        if let firmware = transmitter.firmware {
                            HStack {
                                Text("Transmitter firmware")
                                Spacer()
                                Text(firmware.description)
                            }
                        }
                    },
                    header: {
                        Label("Transmitter details", systemImage: "antenna.radiowaves.left.and.right.circle")
                    }
                )
            }
        }
    }
}

// MARK: - ColoredProgressView

private struct ColoredProgressView: View {
    // MARK: Internal

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .foregroundColor(Color.ui.gray)

                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    }
            }
            .frame(height: 4)
            .cornerRadius(45.0)
        }
    }

    // MARK: Private

    private let value: Double
    private let colors: [Color]
}
