//
//  GlucoseView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - GlucoseView

struct GlucoseView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        VStack(spacing: 20) {
            if let latestGlucose = store.state.latestSensorGlucose {
                HStack(alignment: .lastTextBaseline) {
                    Text(verbatim: latestGlucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit))
                        .font(.system(size: 96))
                        .frame(height: 72)
                        .clipped()
                        .foregroundColor(getGlucoseColor(glucose: latestGlucose))

                    VStack(alignment: .leading) {
                        Text(verbatim: latestGlucose.trend.description)
                            .font(.system(size: 48))

                        if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: store.state.glucoseUnit), latestGlucose.trend != .unknown {
                            Text(verbatim: minuteChange)
                        } else {
                            Text(verbatim: "?".asMinuteChange())
                        }
                    }
                }.padding(.top, 10)

                HStack(spacing: 20) {
                    Spacer()
                    Text(latestGlucose.timestamp, style: .relative)
                        .opacity(0.5)

                    if let warning = warning {
                        Group {
                            Text(verbatim: warning)
                                .padding(.init(top: 2.5, leading: 5, bottom: 2.5, trailing: 5))
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .foregroundStyle(Color.ui.red)
                                )
                        }
                    }

                    Text(verbatim: store.state.glucoseUnit.localizedDescription)
                        .opacity(0.5)
                    Spacer()
                }

            } else {
                Text("No Data")
                    .font(.system(size: 48))
                    .foregroundColor(Color.ui.red)

                HStack(spacing: 20) {
                    Text(verbatim: Date().toLocalTime())

                    Text(verbatim: store.state.glucoseUnit.localizedDescription)
                }
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
                        Text(verbatim: alarmSnoozeUntil.toLocalTime())
                        Image(systemName: "speaker.slash")
                    } else {
                        Image(systemName: "speaker.wave.2")
                    }
                }).opacity(store.state.alarmSnoozeUntil == nil ? 0.5 : 1)
            }
            .disabled(store.state.latestSensorGlucose == nil)
            .buttonStyle(.plain)
        }
    }

    // MARK: Private

    private var warning: String? {
        if let sensor = store.state.sensor, sensor.state != .ready {
            return sensor.state.localizedDescription
        }

        if store.state.connectionState != .connected {
            return store.state.connectionState.localizedDescription
        }

        return nil
    }

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
