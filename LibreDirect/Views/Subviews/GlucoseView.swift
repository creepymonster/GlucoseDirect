//
//  GlucoseView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - GlucoseView

struct GlucoseView: View {
    @EnvironmentObject var store: AppStore

    var isAlarm: Bool {
        if let glucose = store.state.currentGlucose, let glucoseValue = glucose.glucoseValue, glucoseValue < store.state.alarmLow || glucoseValue > store.state.alarmHigh {
            return true
        }

        return false
    }

    var glucoseForegroundColor: Color {
        if isAlarm {
            return Color.ui.red
        }

        return Color.primary
    }

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

                            HStack(spacing: 20) {
                                if store.state.connectionState == .connected {
                                    Text(String(format: LocalizedString("%1$@ a clock"), currentGlucose.timestamp.localTime))
                                    if let minuteChange = currentGlucose.minuteChange?.asMinuteChange(glucoseUnit: store.state.glucoseUnit), currentGlucose.trend != .unknown {
                                        Text(minuteChange)
                                    } else {
                                        Text(String(format: LocalizedString("%1$@/min."), "?"))
                                    }
                                } else if store.state.isPaired {
                                    Text(store.state.connectionState.localizedString)
                                        .foregroundColor(Color.ui.red)
                                }
                            }.padding(.bottom)
                        }

                        if store.state.glucoseAlarm && store.state.isPaired {
                            SnoozeView().padding(.bottom, 5)
                        }
                    } else {
                        VStack(alignment: .center, spacing: 0) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(Color.ui.red)
                                .font(.system(size: 112))

                            Text("Attention, the sensor sends faulty values. Please wait 10 minutes.")
                                .padding(.vertical)
                            
                            Text(String(format: LocalizedString("%1$@ a clock"), currentGlucose.timestamp.localTime))
                        }.padding(.vertical)
                    }
                }
            }
        }
        .animation(.default, value: store.state.connectionState)
        .animation(.default, value: store.state.currentGlucose)
    }
}

// MARK: - GlucoseView_Previews

struct GlucoseView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            GlucoseView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
