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
            MainLockScreenLiveActivityView(context: context.state)
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
        .contentMarginsDisabled()
        .extraActivityFamily()
    }
}

// MARK: - GlucoseStatusContext

@available(iOS 16.1, *)
protocol GlucoseStatusContext {
    var context: SensorGlucoseActivityAttributes.GlucoseStatus { get }
}

@available(iOS 16.1, *)
extension GlucoseStatusContext {
    var c: String? {""}
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
    
    func isWatchAlarm(glucose: any Glucose) -> Bool {
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

    func getGlucoseBackgroundGradient(glucose: any Glucose) -> LinearGradient {
        if glucose.glucoseValue < 55 || glucose.glucoseValue > 280 {
            return LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.9), Color.red.opacity(0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isAlarm(glucose: glucose) {
            return LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [Color.screamingGreen.opacity(0.8), Color.screamingGreen.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
}

extension Color {
    static let screamingGreen = Color(red: 61/255, green: 255/255, blue: 139/255)
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
    }
}

// MARK: - GlucoseActivityView

@available(iOS 16.1, *)
struct GlucoseActivityView: View, GlucoseStatusContext {
    @Environment(\.colorScheme) var colorScheme
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
                        .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
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
 //       .privacySensitive()
 //       .foregroundStyle(Color.primary)
 //       .background(BackgroundStyle.background.opacity(0.6))
//        .activityBackgroundTint(Color.clear)
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

@available(iOS 16.1, *)
struct InitialLockScreenLiveActivityContentView: View {
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus
    
    var body: some View {
        GlucoseActivityView(context: context)
    }
}

@available(iOS 18, *)
struct StackedLiveActivityContentView: View, GlucoseStatusContext {
    @Environment(\.colorScheme) var colorScheme
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var body: some View {
        ZStack {
            if let latestGlucose = context.glucose {
                getGlucoseBackgroundGradient(glucose: latestGlucose)
                    .edgesIgnoringSafeArea(.all)
            }
            HStack(alignment: .center) {
                if let latestGlucose = context.glucose, let glucoseUnit = context.glucoseUnit {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center, spacing: 0) {
                            Spacer()
                            VStack(alignment: .center, spacing: 0) {
                                Group {
                                    if latestGlucose.type != .high {
                                        Text(verbatim: latestGlucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                                    } else {
                                        Text("HIGH")
                                    }
                                }
                                .foregroundColor(.primary)
                                .font(.system(size: 32))
                                .minimumScaleFactor(0.2)
                                .lineLimit(1)
                                .fontWeight(.semibold)
                            }

                            Text(verbatim: latestGlucose.trend.description)
                                .font(.system(size: 20))
                                .minimumScaleFactor(0.2)
                                .lineLimit(1)
                                .foregroundColor(.primary)
                        }

                        if let warning = warning {
                            HStack(alignment: .center) {
                                Text(verbatim: warning)
                                    .font(.footnote)
                          //          .minimumScaleFactor(0.05)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.system(size: 6))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 5) {
                        Text(latestGlucose.timestamp, style: .time)
                            .bold()
                            .monospacedDigit()
                            .foregroundColor(.primary)
                            .fontWeight(.bold)
                            .font(.system(size: 18))

                        if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                            Text(verbatim: minuteChange)
                                .fontWeight(.bold)
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                        } else {
                            Text(verbatim: "?")
                        }

                        if warning == nil {
                            HStack {
                            }
                            .opacity(0.5)
                            .font(.footnote)
                            .font(.system(size: 10))
                            .minimumScaleFactor(0.2)
                        }
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
     
     //   .activityBackgroundTint(.black)
    }
}

@available(iOS 18.0, *)
struct UpdatedLockScreenLiveActivityContentView: View {
    @Environment(\.activityFamily) var activityFamily
    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus
     
    var body: some View {
        switch activityFamily {
        case .small:
            StackedLiveActivityContentView(context: context)
        case .medium:
            GlucoseActivityView(context: context)
        @unknown default:
            MainLockScreenLiveActivityView(context: context)
        }
    }
}

@available(iOS 16.1, *)
struct MainLockScreenLiveActivityView: View {
      @State var context: SensorGlucoseActivityAttributes.GlucoseStatus
    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                UpdatedLockScreenLiveActivityContentView(context: context)
            } else {
                GlucoseActivityView(context: context)
            }
        }
    }
}
