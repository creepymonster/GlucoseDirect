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
                        Text(latestGlucose.glucoseValue.asGlucose(unit: glucoseUnit))
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
                    Text(latestGlucose.glucoseValue.asGlucose(unit: glucoseUnit))
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
                    Text(verbatim: latestGlucose.glucoseValue.asGlucose(unit: glucoseUnit))
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
                }

                if let warning = warning {
                    Text(verbatim: warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.ui.red)
                        .foregroundColor(.white)
                } else {
                    HStack(spacing: 20) {
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
    }
}

// MARK: - GlucoseActivityView

@available(iOS 16.1, *)
struct GlucoseActivityView: View, GlucoseStatusContext {
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var body: some View {
        HStack {
            Spacer()

            VStack(spacing: 10) {
                if let latestGlucose = context.glucose, let glucoseUnit = context.glucoseUnit {
                    HStack(alignment: .lastTextBaseline, spacing: 20) {
                        Text(verbatim: latestGlucose.glucoseValue.asGlucose(unit: glucoseUnit))
                            .font(.system(size: 96))
                            .foregroundColor(getGlucoseColor(glucose: latestGlucose))

                        VStack(alignment: .leading) {
                            Text(verbatim: latestGlucose.trend.description)
                                .font(.system(size: 52))

                            if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                                Text(verbatim: minuteChange)
                            } else {
                                Text(verbatim: "?")
                            }
                        }
                    }

                    if let warning = warning {
                        Text(verbatim: warning)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.ui.red)
                            .foregroundColor(.white)
                    } else {
                        HStack(spacing: 20) {
                            Text(latestGlucose.timestamp, style: .time)
                            Text(verbatim: glucoseUnit.localizedDescription)
                        }.opacity(0.5)
                    }

                } else {
                    Text("No Data")
                        .font(.system(size: 52))
                        .foregroundColor(Color.ui.red)

                    Text(Date(), style: .time)
                        .opacity(0.5)
                }
            }

            Spacer()
        }.padding([.trailing, .bottom, .leading])
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
                sensorState: .expired,
                connectionState: .disconnected,
                glucose: SensorGlucose(glucoseValue: 120, minuteChange: 2),
                glucoseUnit: .mgdL,
                startDate: Date(),
                restartDate: Date(),
                stopDate: Date()
            )
        ).previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
