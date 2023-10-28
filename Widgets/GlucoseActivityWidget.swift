//
//  GlucoseActivityWidget.swift
//  GlucoseDirect
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - GlucoseActivityWidget

@available(iOS 16.1, *)
struct GlucoseActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SensorGlucoseActivityAttributes.self) { context in
            GlucoseActivityView(context: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    DynamicIslandCenterView(context: context.state)
                }
            } compactLeading: {
                if let latestGlucose = context.state.glucose,
                   let glucoseUnit = context.state.glucoseUnit,
                   let connectionState = context.state.connectionState
                {
                    VStack(alignment: .trailing) {
                        Text(latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                            .font(.body)
                            .fontWeight(.bold)
                            .strikethrough(connectionState != .connected, color: Color.ui.red)

                        Text(glucoseUnit.shortLocalizedDescription)
                            .font(.system(size: 12))
                    }.padding(.leading, 7.5)
                }
            } compactTrailing: {
                if let latestGlucose = context.state.glucose,
                   let glucoseUnit = context.state.glucoseUnit
                {
                    VStack(alignment: .trailing) {
                        Text(latestGlucose.trend.description)
                            .font(.body)
                            .fontWeight(.bold)

                        if let minuteChange = latestGlucose.minuteChange?.asShortMinuteChange(glucoseUnit: glucoseUnit), latestGlucose.trend != .unknown {
                            Text(minuteChange)
                                .font(.system(size: 12))
                        }
                    }.padding(.trailing, 7.5)
                }
            } minimal: {
                if let latestGlucose = context.state.glucose,
                   let glucoseUnit = context.state.glucoseUnit,
                   let connectionState = context.state.connectionState
                {
                    Text(latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .font(.body)
                        .strikethrough(connectionState != .connected, color: Color.ui.red)
                }
            }
        }
    }
}

// MARK: - GlucoseStatusContext

@available(iOS 16.1, *)
protocol GlucoseStatusContext {
    var context: SensorGlucoseActivityAttributes.GlucoseStatus { get }
}

@available(iOS 16.1, *)
extension GlucoseStatusContext {
    var warning: String? {
        if let sensorState = context.sensorState, sensorState != .ready {
            return sensorState.localizedDescription
        }

        if let connectionState = context.connectionState, connectionState != .connected {
            return connectionState.localizedDescription
        }

        return nil
    }

    func isAlarm(glucose: any Glucose) -> Bool {
        if glucose.glucoseValue < context.alarmLow || glucose.glucoseValue > context.alarmHigh {
            return true
        }

        return false
    }

    func getGlucoseColor(glucose: any Glucose) -> Color {
        if isAlarm(glucose: glucose) {
            return Color.ui.red
        }

        return Color.primary
    }
}

// MARK: - DynamicIslandCenterView

@available(iOS 16.1, *)
struct DynamicIslandCenterView: View, GlucoseStatusContext {
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var body: some View {
        VStack(spacing: 0) {
            if let latestGlucose = context.glucose, let glucoseUnit = context.glucoseUnit {
                HStack(alignment: .lastTextBaseline, spacing: 20) {
                    if latestGlucose.type != .high {
                        Text(verbatim: latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                            .font(.system(size: 64))
                            .foregroundColor(getGlucoseColor(glucose: latestGlucose))

                        VStack(alignment: .leading) {
                            Text(verbatim: latestGlucose.trend.description)
                                .font(.system(size: 34))

                            if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                                Text(verbatim: minuteChange)
                            } else {
                                Text(verbatim: "?")
                            }
                        }
                    } else {
                        Text("HIGH")
                            .font(.system(size: 64))
                            .foregroundColor(getGlucoseColor(glucose: latestGlucose))
                    }
                }

                if let warning = warning {
                    Text(verbatim: warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.ui.red)
                        .foregroundColor(.white)
                } else {
                    HStack(spacing: 40) {
                        Text(latestGlucose.timestamp, style: .time)
                        Text(verbatim: glucoseUnit.localizedDescription)
                    }.opacity(0.5)
                }

            } else {
                Text("No Data")
                    .font(.system(size: 34))
                    .foregroundColor(Color.ui.red)

                Text(Date(), style: .time)
                    .opacity(0.5)
            }
        }.padding(.bottom)
        .widgetBackground(backgroundView: Color("WidgetBackground"))
    }
}

// MARK: - GlucoseActivityView

@available(iOS 16.1, *)
struct GlucoseActivityView: View, GlucoseStatusContext {
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Spacer()

            if let latestGlucose = context.glucose, let glucoseUnit = context.glucoseUnit {
                VStack {
                    HStack(alignment: .top) {
                        Group {
                            if latestGlucose.type != .high {
                                Text(verbatim: latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                            } else {
                                Text("HIGH")
                            }
                        }
                        .bold()
                        .foregroundColor(getGlucoseColor(glucose: latestGlucose))
                        .font(.system(size: 40))
                        
                        Text(verbatim: latestGlucose.trend.description)
                            .foregroundColor(getGlucoseColor(glucose: latestGlucose))
                            .font(.system(size: 32))
                    }
                    
                    if let warning = warning {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(Color.ui.red)
                            
                            Text(verbatim: warning)
                                .bold()
                        }
                        .font(.footnote)
                    } else {
                        HStack {
                            Text(verbatim: glucoseUnit.localizedDescription)
                            
                            Group {
                                if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                                    Text(verbatim: minuteChange)
                                } else {
                                    Text(verbatim: "?")
                                }
                            }
                        }
                        .opacity(0.5)
                        .font(.footnote)
                    }
                }
                
                Spacer()

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 10) {
                        Text("Updated")
                            .opacity(0.5)
                            .textCase(.uppercase)
                        
                        Text(latestGlucose.timestamp, style: .time)
                            .bold()
                            .monospacedDigit()
                    }
                    
                    if let stopDate = context.stopDate {
                        Text("Reopen app in")
                            .opacity(0.5)
                            .textCase(.uppercase)

                        Text(stopDate, style: .relative)
                            .bold()
                            .multilineTextAlignment(.leading)
                            .monospacedDigit()
                    }
                }
                .font(.footnote)
                .frame(maxWidth: 175)

            } else {
                VStack(spacing: 10) {
                    Text("No Data")
                        .bold()
                        .font(.system(size: 35))
                        .foregroundColor(Color.ui.red)

                    Text(Date(), style: .time)
                        .opacity(0.5)
                        .font(.footnote)
                }

                Spacer()
            }
        }
        .padding(.top, 5)
        .padding(.bottom, 10)
        .widgetBackground(backgroundView: Color("WidgetBackground"))
    }
}

// MARK: - GlucoseActivityWidget_Previews

@available(iOS 16.1, *)
struct GlucoseActivityWidget_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseActivityView(
            context: SensorGlucoseActivityAttributes.GlucoseStatus(
                alarmLow: 80,
                alarmHigh: 160,
                sensorState: .expired,
                connectionState: .disconnected,
                glucoseUnit: .mgdL,
                startDate: Date(),
                restartDate: Date(),
                stopDate: Date()
            )
        ).previewContext(WidgetPreviewContext(family: .systemMedium))

        GlucoseActivityView(
            context: SensorGlucoseActivityAttributes.GlucoseStatus(
                alarmLow: 80,
                alarmHigh: 160,
                sensorState: .ready,
                connectionState: .connected,
                glucose: SensorGlucose(glucoseValue: 120, minuteChange: 2),
                glucoseUnit: .mgdL,
                startDate: Date(),
                restartDate: Date(),
                stopDate: Date()
            )
        ).previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
