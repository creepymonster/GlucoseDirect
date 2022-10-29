//
//  GlucoseView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - GlucoseView

struct GlucoseView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var warning: String? {
        if let sensor = store.state.sensor, sensor.state != .ready {
            return sensor.state.localizedDescription
        }

        if store.state.connectionState != .connected {
            return store.state.connectionState.localizedDescription
        }

        return nil
    }

    var body: some View {
        if let latestGlucose = store.state.latestSensorGlucose {
            VStack(spacing: 20) {
                HStack(alignment: .lastTextBaseline) {
                    Text(latestGlucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit))
                        .font(.system(size: 96))
                        .frame(height: 72)
                        .clipped()
                        .foregroundColor(getGlucoseColor(glucose: latestGlucose))

                    VStack(alignment: .leading) {
                        Text(latestGlucose.trend.description)
                            .font(.system(size: 48))

                        if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: store.state.glucoseUnit), latestGlucose.trend != .unknown {
                            Text(minuteChange)
                        } else {
                            Text("?".asMinuteChange())
                        }
                    }
                }

                HStack(spacing: 20) {
                    Spacer()
                    Text(latestGlucose.timestamp.toLocalTime()).opacity(0.5)

                    if let warning = warning {
                        Group {
                            Text(warning)
                                .padding(.init(top: 2.5, leading: 5, bottom: 2.5, trailing: 5))
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .foregroundStyle(Color.ui.red)
                                )
                        }
                    }

                    Text(store.state.glucoseUnit.localizedDescription).opacity(0.5)
                    Spacer()
                }
                
                HStack {
                    Button(action: {
                        DirectNotifications.shared.hapticFeedback()
                        store.dispatch(.setPreventScreenLock(enabled: !store.state.preventScreenLock))
                    }, label: {
                        if store.state.preventScreenLock {
                            Image(systemName: "lock.slash")
                            Text("No screen lock")
                        } else {
                            Image(systemName: "lock")
                        }
                    }).opacity(store.state.preventScreenLock ? 1 : 0.5)

                    Spacer()

                    if store.state.alarmSnoozeUntil != nil {
                        Button(action: {
                            DirectNotifications.shared.hapticFeedback()
                            store.dispatch(.setAlarmSnoozeUntil(untilDate: nil))
                        }, label: {
                            Image(systemName: "delete.forward")
                        }).padding(.trailing, 5)
                    }

                    Button(action: {
                        let date = (store.state.alarmSnoozeUntil ?? Date()).toRounded(on: 1, .minute)
                        let nextDate = Calendar.current.date(byAdding: .minute, value: 60, to: date)

                        DirectNotifications.shared.hapticFeedback()
                        store.dispatch(.setAlarmSnoozeUntil(untilDate: nextDate))
                    }, label: {
                        if let alarmSnoozeUntil = store.state.alarmSnoozeUntil {
                            Text(alarmSnoozeUntil.toLocalTime())
                            Image(systemName: "speaker.slash")
                        } else {
                            Image(systemName: "speaker.wave.2")
                        }
                    }).opacity(store.state.alarmSnoozeUntil == nil ? 0.5 : 1)
                }
                .buttonStyle(.plain)
            }.padding(.vertical, 10)
        } else {
            VStack {
                Text("No Data")
                    .font(.system(size: 48))
                    .foregroundColor(Color.ui.red)
                    .padding(.vertical)
            }
        }
    }

    // MARK: Private

    private func isAlarm(glucose: any Glucose) -> Bool {
        if glucose.glucoseValue < store.state.alarmLow || glucose.glucoseValue > store.state.alarmHigh {
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
