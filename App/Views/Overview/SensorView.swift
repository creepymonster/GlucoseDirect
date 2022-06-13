//
//  DetailsView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - SensorView

struct SensorView: View {
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var store: AppStore
    @State var deviceColorScheme = ColorScheme.light

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

                        if let startTimestamp = sensor.startTimestamp {
                            HStack {
                                Text("Sensor starting date")
                                Spacer()
                                Text(startTimestamp.toLocalDateTime())
                            }
                        }

                        if let remainingWarmupTime = sensor.remainingWarmupTime, sensor.state == .starting {
                            HStack {
                                Text("Sensor remaining warmup time")
                                Spacer()

                                if #available(iOS 16.0, *) {
                                    Gauge(value: 50, in: 0...100) {
                                        Text(remainingWarmupTime.inTime)
                                    }.gaugeStyle(.accessoryLinearCapacity)
                                } else {
                                    Text(remainingWarmupTime.inTime)
                                }
                            }
                        } else if sensor.state != .expired && sensor.state != .shutdown && sensor.state != .unknown {
                            HStack {
                                Text("Sensor possible lifetime")
                                Spacer()
                                Text(sensor.lifetime.inTime)
                            }

                            HStack {
                                Text("Sensor age")
                                Spacer()

                                if #available(iOS 16.0, *) {
                                    Gauge(value: 50, in: 0...100) {
                                        Text(sensor.age.inTime)
                                    }.gaugeStyle(.accessoryLinearCapacity)
                                } else {
                                    Text(sensor.age.inTime)
                                }
                            }

                            if let remainingLifetime = sensor.remainingLifetime {
                                HStack {
                                    Text("Sensor remaining lifetime")
                                    Spacer()

                                    if #available(iOS 16.0, *) {
                                        Gauge(value: 50, in: 0...100) {
                                            Text(remainingLifetime.inTime)
                                        }.gaugeStyle(.accessoryLinearCapacity)
                                    } else {
                                        Text(remainingLifetime.inTime)
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

                        HStack {
                            Text("Transmitter battery")
                            Spacer()

                            if #available(iOS 16.0, *) {
                                Gauge(value: 50, in: 0...100) {
                                    Text("\(transmitter.battery)%")
                                }.gaugeStyle(.accessoryLinearCapacity)
                            } else {
                                Text("\(transmitter.battery)%")
                            }
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
                        Label("Transmitter Details", systemImage: "antenna.radiowaves.left.and.right.circle")
                    }
                )
            }
        }.onChange(of: colorScheme) { scheme in
            if deviceColorScheme != scheme {
                DirectLog.info("onChange colorScheme: \(scheme)")

                deviceColorScheme = scheme
            }
        }
    }
}

// TEST
