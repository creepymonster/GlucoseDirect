//
//  GlucoseView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - GlucoseView

struct GlucoseView: View {
    @EnvironmentObject var store: AppStore

    var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.positivePrefix = "+"
        formatter.maximumFractionDigits = 1

        return formatter
    }

    var minuteChange: String {
        if let minuteChange = store.state.currentGlucose?.minuteChange {
            if store.state.glucoseUnit == .mgdL {
                return formatter.string(from: minuteChange as NSNumber)!
            } else {
                return formatter.string(from: minuteChange.asMmolL as NSNumber)!
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
            return Color.red
        }

        return Color.primary
    }

    var body: some View {
        if let currentGlucose = store.state.currentGlucose {
            VStack(alignment: .center) {
                ZStack(alignment: .bottomTrailing) {
                    Text(currentGlucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit))
                        .font(.system(size: 112))
                        .foregroundColor(glucoseForegroundColor)

                    Text(store.state.glucoseUnit.localizedString)
                }

                HStack {
                    Text(String(format: LocalizedString("%1$@ a clock"), currentGlucose.timestamp.localTime)).frame(width: 120, alignment: .leading)
                    Spacer()
                    
                    if let lastGlucose = store.state.lastGlucose {
                        Text(lastGlucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit, withUnit: true)).foregroundColor(.gray)
                        Spacer()
                    }

                    if let _ = store.state.lastGlucose?.minuteChange, currentGlucose.trend != .unknown {
                        Text("\(currentGlucose.trend.description) \(String(format: LocalizedString("%1$@/min."), minuteChange))").frame(width: 120, alignment: .trailing)
                    } else {
                        Text(String(format: LocalizedString("%1$@/min."), "?")).frame(width: 120, alignment: .trailing)
                    }
                }.padding(.top, 10)
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
