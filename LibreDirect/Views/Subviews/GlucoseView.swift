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

        return ""
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
            VStack {
                Text(glucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit)).font(.system(size: 96)).foregroundColor(glucoseForegroundColor)

                HStack {
                    Spacer()

                    if let _ = glucose.minuteChange {
                        Text(glucose.trend.description)
                        Text(String(format: LocalizedString("%1$@/min.", comment: ""), minuteChange))
                        Spacer()
                    }

                    Text("Last update")
                    Text(String(format: LocalizedString("%1$@ a clock"), glucose.timestamp.localTime))
                    Spacer()
                }
                .font(.footnote)
                .padding(.bottom, 5)
            }
        }
    }
}
