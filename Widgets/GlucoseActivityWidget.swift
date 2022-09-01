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
        ActivityConfiguration(attributesType: SensorGlucoseActivityAttributes.self) { context in
            GlucoseActivityView(context: context.state)
        }
    }
}

// MARK: - GlucoseActivityView

@available(iOS 16.1, *)
struct GlucoseActivityView: View {
    // MARK: Internal

    @State var context: SensorGlucoseActivityAttributes.GlucoseStatus

    var warning: String? {
        if let sensorState = context.sensorState, sensorState != .ready {
            return sensorState.localizedDescription
        }

        if let connectionState = context.connectionState, connectionState != .connected {
            return connectionState.localizedDescription
        }

        return nil
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if let latestGlucose = context.glucose,
               let glucoseUnit = context.glucoseUnit
            {
                HStack(alignment: .lastTextBaseline) {
                    ZStack(alignment: .trailing) {
                        Text(latestGlucose.glucoseValue.asGlucose(unit: glucoseUnit))
                            .font(.system(size: 96))
                            .frame(height: 96)
                            .clipped()

                        if let warning = warning {
                            Group {
                                Text(warning)
                                    .padding(.init(top: 2.5, leading: 5, bottom: 2.5, trailing: 5))
                                    .foregroundColor(.white)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .foregroundStyle(Color.ui.red)
                                    )
                            }.offset(y: 32)
                        }

                        HStack(spacing: 16) {
                            Text(latestGlucose.timestamp.toLocalTime())
                            Text(glucoseUnit.localizedDescription)
                        }.offset(y: 58)
                    }

                    VStack(alignment: .leading) {
                        Text(latestGlucose.trend.description)
                            .font(.system(size: 48))

                        if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit), latestGlucose.trend != .unknown {
                            Text(minuteChange)
                        } else {
                            Text("?".asMinuteChange())
                        }
                    }
                }.padding(.bottom, 32)

                if let stopDate = context.stopDate {
                    Text("Reopen app by \(stopDate.toLocalTime()) at the latest. Otherwise iOS automatically disables the widget :(")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(0.5)
                }
            } else {
                VStack {
                    Text("No Data")
                        .font(.system(size: 48))
                        .foregroundColor(Color.ui.red)
                        .padding(.bottom)

                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "questionmark.bubble")
                        Text("Set, activate (with LibreLink App) and connect the first sensor to get data.")
                    }
                }
            }
        }.padding()
    }

    // MARK: Private

    private func isAlarm(glucose: any Glucose) -> Bool {
        if glucose.glucoseValue < context.alarmLow || glucose.glucoseValue > context.alarmHigh {
            return true
        }

        return false
    }

    private func getGlucoseColor(glucose: any Glucose) -> Color {
        if isAlarm(glucose: glucose) {
            return Color.ui.red
        }

        return Color.primary
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

// TODO
