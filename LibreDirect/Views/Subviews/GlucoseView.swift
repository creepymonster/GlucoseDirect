//
//  GlucoseView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - GlucoseView

struct GlucoseView: View {
    @EnvironmentObject var store: AppStore

    var minuteChange: String {
        if let minuteChange = store.state.currentGlucose?.minuteChange {
            if store.state.glucoseUnit == .mgdL {
                return GlucoseFormatters.minuteChangeFormatter.string(from: minuteChange as NSNumber)!
            } else {
                return GlucoseFormatters.minuteChangeFormatter.string(from: minuteChange.asMmolL as NSNumber)!
            }
        }

        return "?"
    }

    var isAlarm: Bool {
        if let glucose = store.state.currentGlucose, glucose.glucoseValue < store.state.alarmLow || glucose.glucoseValue > store.state.alarmHigh {
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
        if let currentGlucose = store.state.currentGlucose {
            VStack(alignment: .center) {
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(currentGlucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit))
                            .font(.system(size: 112))

                        VStack(alignment: .leading) {
                            Text(currentGlucose.trend.description).font(.system(size: 48))

                            Text(store.state.glucoseUnit.localizedString)
                        }
                    }.foregroundColor(glucoseForegroundColor)

                    HStack(spacing: 20) {
                        if store.state.connectionState == .connected {
                            Text(String(format: LocalizedString("%1$@ a clock"), currentGlucose.timestamp.localTime))
                            if let _ = store.state.lastGlucose?.minuteChange, currentGlucose.trend != .unknown {
                                Text(String(format: LocalizedString("%1$@/min."), minuteChange))
                            } else {
                                Text(String(format: LocalizedString("%1$@/min."), "?"))
                            }
                        } else if store.state.isPaired {
                            Text(store.state.connectionState.localizedString).foregroundColor(Color.ui.red)
                        }
                    }.padding(.bottom)
                }

                if store.state.glucoseAlarm && store.state.isPaired {
                    SnoozeView().padding(.bottom, 5)
                }
            }
        }
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
