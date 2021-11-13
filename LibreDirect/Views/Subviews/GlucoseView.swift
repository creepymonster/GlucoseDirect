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
        if let minuteChange = store.state.lastGlucose?.minuteChange {
            if store.state.glucoseUnit == .mgdL {
                return formatter.string(from: minuteChange as NSNumber)!
            } else {
                return formatter.string(from: minuteChange.asMmolL as NSNumber)!
            }
        }

        return "?"
    }

    var glucoseForegroundColor: Color {
        if let glucose = store.state.lastGlucose {
            if glucose.glucoseValue < store.state.alarmLow {
                return Color.red
            }

            if glucose.glucoseValue > store.state.alarmHigh {
                return Color.red
            }
        }

        return Color.primary
    }

    var body: some View {
        if let glucose = store.state.lastGlucose {
            VStack(alignment: .center) {
                ZStack(alignment: .bottomTrailing) {
                    Text(glucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit))
                        .font(.system(size: 96))
                        .foregroundColor(glucoseForegroundColor)

                    Text(store.state.glucoseUnit.localizedString)
                }
                
                HStack {
                    Spacer()
                    Text("(\(glucose.factoryCalibratedGlucoseValue.asGlucose(unit: store.state.glucoseUnit, withUnit: true)))")
                    Spacer()
                }
                .font(.footnote)

                HStack {
                    Text("Change:")
                    if glucose.trend != .unknown {
                        Text(glucose.trend.description)
                        Text(String(format: LocalizedString("%1$@/min.", comment: ""), minuteChange))
                    } else {
                        Text("...")
                    }
                    
                    Spacer()

                    Text("Last update:")
                    Text(String(format: LocalizedString("%1$@ a clock"), glucose.timestamp.localTime))
                }
                .font(.footnote)
                .padding(.top, 15)
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
