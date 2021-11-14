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

        return Color.accentColor
    }

    var body: some View {
        if let glucose = store.state.lastGlucose {
            VStack(alignment: .trailing) {
                ZStack(alignment: .bottomTrailing) {
                    Text(glucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit))
                        .font(.system(size: 96))
                        .foregroundColor(glucoseForegroundColor)
                        .padding(.bottom, 5)

                    Text(store.state.glucoseUnit.localizedString)
                }

                HStack {
                    Spacer()
                    
                    Text("Trend:")
                    
                    if glucose.trend != .unknown {
                        Text(glucose.trend.description).fontWeight(.semibold).foregroundColor(.accentColor)
                        Text(String(format: LocalizedString("%1$@/min."), minuteChange)).fontWeight(.semibold).foregroundColor(.accentColor)
                    } else {
                        Text(String(format: LocalizedString("%1$@/min."), "...")).fontWeight(.semibold).foregroundColor(.accentColor)
                    }
                }
                .padding(.top, 5)
                
                HStack {
                    Spacer()
                    Text("Last update:")
                    Text(String(format: LocalizedString("%1$@ a clock"), glucose.timestamp.localTime)).fontWeight(.semibold).foregroundColor(.accentColor)
                }
                .padding(.top, 5)

                HStack {
                    Spacer()
                    Text("Factory calibrated glucose:")
                    Text(glucose.factoryCalibratedGlucoseValue.asGlucose(unit: store.state.glucoseUnit, withUnit: true)).fontWeight(.semibold).foregroundColor(.accentColor)
                }
                .padding(.top, 5)
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
