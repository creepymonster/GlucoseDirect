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
            if let glucose = context.state.glucose,
               let glucoseUnit = context.state.glucoseUnit
            {
                VStack(alignment: .center, spacing: 0) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(glucose.glucoseValue.asGlucose(unit: glucoseUnit))
                            .font(.system(size: 96))

                        VStack(alignment: .center) {
                            Text(glucose.trend.description)
                                .font(.system(size: 52))
                                .bold()

                            Text(glucoseUnit.localizedString)
                                .foregroundStyle(Color.primary)
                        }.padding(.leading, 5)
                    }.foregroundColor(getGlucoseColor(alarmLow: context.state.alarmLow, alarmHigh: context.state.alarmHigh, glucose: glucose))

                    HStack(spacing: 20) {
                        Spacer()
                        Text(glucose.timestamp.toLocalTime())
                        Spacer()

                        if let minuteChange = glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit), glucose.trend != .unknown {
                            Text(minuteChange)
                        } else {
                            Text("?".asMinuteChange())
                        }

                        Spacer()
                    }
                    .padding(.bottom)

                    if let startDate = context.state.startDate,
                       let restartDate = context.state.restartDate,
                       let stopDate = context.state.stopDate
                    {
                        HStack(spacing: 20) {
                            Spacer()
                            
                            VStack {
                                Text("Start").bold()
                                Text(startDate.toLocalTime())
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("Restart").bold()
                                Text(restartDate.toLocalTime())
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("Stop").bold()
                                Text(stopDate.toLocalTime())
                            }
                            
                            Spacer()
                        }
                        .padding(.bottom)
                        .font(.footnote)
                        .opacity(0.5)
                    }
                }
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
