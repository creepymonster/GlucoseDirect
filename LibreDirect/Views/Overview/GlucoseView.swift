//
//  GlucoseView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - GlucoseView

struct GlucoseView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            if let currentGlucose = store.state.currentGlucose {
                VStack(alignment: .center) {
                    if let glucoseValue = currentGlucose.glucoseValue {
                        VStack(alignment: .trailing, spacing: 0) {
                            HStack(alignment: .lastTextBaseline) {
                                Text(glucoseValue.asGlucose(unit: store.state.glucoseUnit))
                                    .font(.system(size: 96))

                                VStack(alignment: .leading) {
                                    Text(currentGlucose.trend.description).font(.system(size: 48))

                                    Text(store.state.glucoseUnit.localizedString)
                                }
                            }.foregroundColor(glucoseForegroundColor)

                            if let minuteChange = currentGlucose.minuteChange?.asMinuteChange(glucoseUnit: store.state.glucoseUnit), currentGlucose.trend != .unknown {
                                HStack(spacing: 20) {
                                    Text(String(format: LocalizedString("%1$@ a clock"), currentGlucose.timestamp.toLocalTime()))
                                    Text(minuteChange)
                                }.padding(.bottom)
                            }
                        }
                    } else if currentGlucose.isHIGH || currentGlucose.isLOW {
                        VStack(alignment: .trailing, spacing: 0) {
                            HStack(alignment: .lastTextBaseline) {
                                if currentGlucose.isHIGH {
                                    VStack(alignment: .center, spacing: 0) {
                                        Text("HIGH")
                                            .font(.system(size: 96))
                                            .foregroundColor(Color.ui.red)

                                        Text("Caution, a sudden, extremely high glucose value may indicate a sensor error. Please check this value with a blood glucose meter.")
                                            .padding(.vertical)
                                        
                                        Text("The value from the blood glucose meter can then be added via 'List', at the top 'Add'.")
                                            .padding(.vertical)
                                    }
                                } else if currentGlucose.isLOW {
                                    Text("LOW")
                                        .font(.system(size: 96))
                                        .foregroundColor(Color.ui.red)
                                }
                            }.foregroundColor(glucoseForegroundColor)
                        }
                    } else {
                        VStack(alignment: .center, spacing: 0) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(Color.ui.red)
                                .font(.system(size: 112))

                            Text("Attention, the sensor sends faulty values. Please wait 10 minutes.")
                                .padding(.vertical)

                            Text(String(format: LocalizedString("%1$@ a clock"), currentGlucose.timestamp.toLocalTime()))
                        }.padding(.vertical)
                    }
                }
            }
        }
    }

    // MARK: Private

    private var isAlarm: Bool {
        if let glucose = store.state.currentGlucose, let glucoseValue = glucose.glucoseValue, glucoseValue < store.state.alarmLow || glucoseValue > store.state.alarmHigh {
            return true
        }

        return false
    }

    private var glucoseForegroundColor: Color {
        if isAlarm {
            return Color.ui.red
        }

        return Color.primary
    }
}
