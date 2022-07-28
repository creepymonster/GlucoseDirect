//
//  GlucoseActivityWidget.swift
//  GlucoseDirect
//

import ActivityKit
import SwiftUI
import WidgetKit

struct GlucoseActivityWidget: Widget {
    // MARK: Internal

    var body: some WidgetConfiguration {
        ActivityConfiguration(attributesType: SensorGlucoseActivityAttributes.self) { context in
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .lastTextBaseline) {
                    Text(context.state.glucose.glucoseValue.asGlucose(unit: context.state.glucoseUnit))
                        .font(.system(size: 96))

                    VStack(alignment: .center) {
                        Text(context.state.glucose.trend.description)
                            .font(.system(size: 52))
                            .bold()

                        Text(context.state.glucoseUnit.localizedString)
                            .foregroundStyle(Color.primary)
                    }.padding(.leading, 5)
                }.foregroundColor(getGlucoseColor(alarmLow: context.state.alarmLow, alarmHigh: context.state.alarmHigh, glucose: context.state.glucose))

                HStack(spacing: 20) {
                    Spacer()
                    Text(context.state.glucose.timestamp.toLocalTime())
                    Spacer()

                    if let minuteChange = context.state.glucose.minuteChange?.asMinuteChange(glucoseUnit: context.state.glucoseUnit), context.state.glucose.trend != .unknown {
                        Text(minuteChange)
                    } else {
                        Text("?".asMinuteChange())
                    }

                    Spacer()
                }
                .padding(.bottom)
                .opacity(0.5)
            }
        }
    }

    // MARK: Private

    private func isAlarm(alarmLow: Int, alarmHigh: Int, glucose: any Glucose) -> Bool {
        if glucose.glucoseValue < alarmLow || glucose.glucoseValue > alarmHigh {
            return true
        }

        return false
    }

    private func getGlucoseColor(alarmLow: Int, alarmHigh: Int, glucose: any Glucose) -> Color {
        if isAlarm(alarmLow: alarmLow, alarmHigh: alarmHigh, glucose: glucose) {
            return Color.ui.red
        }

        return Color.primary
    }
}
