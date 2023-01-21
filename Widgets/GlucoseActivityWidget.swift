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
                    DynamicIslandExpandedView(context: context.state)
                }
            } compactLeading: {
                DynamicIslandCompactLeadingView(context: context.state)
            } compactTrailing: {
                DynamicIslandCompactTrailingView(context: context.state)
            } minimal: {
                DynamicIslandMinimalView(context: context.state)
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
    var sensorState: SensorState? {
        context.sensorState
    }

    var connectionState: SensorConnectionState? {
        context.connectionState
    }

    var glucoseUnit: GlucoseUnit? {
        context.glucoseUnit
    }

    var glucose: SensorGlucose? {
        context.glucose
    }
}

// MARK: - DynamicIslandCompactLeadingView

@available(iOS 16.1, *)
struct DynamicIslandCompactLeadingView: View, GlucoseStatusContext {
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var body: some View {
        if let glucose,
           let glucoseUnit
        {
            VStack(alignment: .trailing) {
                Text(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                    .font(.body)
                    .bold()
                    .ifLet(connectionState) { $0.strikethrough($1 != .connected, color: Color.ui.red) }

                Text(glucoseUnit.shortLocalizedDescription)
                    .font(.system(size: 12))
            }.padding(.leading, 7.5)
        }
    }
}

// MARK: - DynamicIslandCompactTrailingView

@available(iOS 16.1, *)
struct DynamicIslandCompactTrailingView: View, GlucoseStatusContext {
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var body: some View {
        if let glucose,
           let glucoseUnit
        {
            VStack(alignment: .trailing) {
                Text(glucose.trend.description)
                    .font(.body)

                if let minuteChange = glucose.minuteChange?.asShortMinuteChange(glucoseUnit: glucoseUnit) {
                    Text(minuteChange)
                        .font(.system(size: 12))
                }
            }.padding(.trailing, 7.5)
        }
    }
}

// MARK: - DynamicIslandMinimalView

@available(iOS 16.1, *)
struct DynamicIslandMinimalView: View, GlucoseStatusContext {
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var body: some View {
        if let glucose,
           let glucoseUnit
        {
            Text(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                .font(.body)
                .ifLet(connectionState) { $0.strikethrough($1 != .connected, color: Color.ui.red) }
        }
    }
}

// MARK: - DynamicIslandExpandedView

@available(iOS 16.1, *)
struct DynamicIslandExpandedView: View, GlucoseStatusContext {
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var body: some View {
        VStack(spacing: 0) {
            if let glucose,
               let glucoseUnit
            {
                HStack(alignment: .lastTextBaseline, spacing: 20) {
                    Text(verbatim: glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .bold()
                        .font(.system(size: 64))
                        .foregroundColor(DirectHelper.getGlucoseColor(glucose: glucose))

                    VStack(alignment: .leading) {
                        Text(verbatim: glucose.trend.description)
                            .font(.system(size: 34))

                        if let minuteChange = glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                            Text(verbatim: minuteChange)
                        } else {
                            Text(verbatim: "?")
                        }
                    }
                }

                if let warning = DirectHelper.getWarning(sensorState: sensorState, connectionState: connectionState) {
                    Text(verbatim: warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.ui.red)
                        .foregroundColor(.white)
                } else {
                    HStack(spacing: 40) {
                        Text(glucose.timestamp, style: .time)
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
        HStack(alignment: .lastTextBaseline) {
            Spacer()

            if let glucose,
               let glucoseUnit
            {
                VStack {
                    HStack(alignment: .top) {
                        Text(verbatim: glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                            .bold()
                            .font(.system(size: 40))
                            .foregroundColor(DirectHelper.getGlucoseColor(glucose: glucose))

                        Text(verbatim: glucose.trend.description)
                            .font(.system(size: 32))
                    }

                    if let warning = DirectHelper.getWarning(sensorState: sensorState, connectionState: connectionState) {
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

                            if let minuteChange = glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                                Text(verbatim: minuteChange)
                            } else {
                                Text(verbatim: "?")
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

                        Text(glucose.timestamp, style: .time)
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
    }
}

// MARK: - GlucoseActivityWidget_Previews

@available(iOSApplicationExtension 16.2, *)
struct GlucoseActivityWidget_Previews: PreviewProvider {
    static let state = SensorGlucoseActivityAttributes.ContentState(
        alarmLow: 80,
        alarmHigh: 160,
        sensorState: .ready,
        connectionState: .connected,
        glucose: SensorGlucose(glucoseValue: 120, minuteChange: 2),
        glucoseUnit: .mmolL,
        startDate: Date(),
        restartDate: Date(),
        stopDate: Date()
    )

    static var previews: some View {
        SensorGlucoseActivityAttributes()
            .previewContext(state, viewKind: .dynamicIsland(.compact))
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))

        SensorGlucoseActivityAttributes()
            .previewContext(state, viewKind: .dynamicIsland(.expanded))
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))

        SensorGlucoseActivityAttributes()
            .previewContext(state, viewKind: .dynamicIsland(.minimal))
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))

        SensorGlucoseActivityAttributes()
            .previewContext(state, viewKind: .content)
    }
}
