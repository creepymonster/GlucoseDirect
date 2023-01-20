//
//  GlucoseView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - GlucoseView

struct GlucoseView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        VStack(spacing: 0) {
            if let latestGlucose = store.state.latestSensorGlucose {
                HStack(alignment: .lastTextBaseline, spacing: 20) {
                    Text(verbatim: latestGlucose.glucoseValue.asGlucose(glucoseUnit: store.state.glucoseUnit))
                        .bold()
                        .font(.system(size: 80))
                        .foregroundColor(DirectHelper.getGlucoseColor(glucose: latestGlucose))

                    VStack(alignment: .leading) {
                        Text(verbatim: latestGlucose.trend.description)
                            .font(.system(size: 40))

                        if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: store.state.glucoseUnit) {
                            Text(verbatim: minuteChange)
                        } else {
                            Text(verbatim: "?")
                        }
                    }
                }

                if let warning = DirectHelper.getWarning(sensorState: store.state.sensor?.state, connectionState: store.state.connectionState) {
                    Text(verbatim: warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.ui.red)
                        .foregroundColor(.white)
                } else {
                    HStack(spacing: 40) {
                        Text(latestGlucose.timestamp, style: .time)
                        Text(verbatim: store.state.glucoseUnit.localizedDescription)
                    }.opacity(0.5)
                }

            } else {
                Text("No Data")
                    .font(.system(size: 40))
                    .foregroundColor(Color.ui.red)

                Text(Date(), style: .time)
                    .opacity(0.5)
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
                        Text(verbatim: "")
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
                    let nextDate = Calendar.current.date(byAdding: .minute, value: 30, to: date)

                    DirectNotifications.shared.hapticFeedback()
                    store.dispatch(.setAlarmSnoozeUntil(untilDate: nextDate))
                }, label: {
                    if let alarmSnoozeUntil = store.state.alarmSnoozeUntil {
                        Text(verbatim: alarmSnoozeUntil.toLocalTime())
                        Image(systemName: "speaker.slash")
                    } else {
                        Text(verbatim: "")
                        Image(systemName: "speaker.wave.2")
                    }
                }).opacity(store.state.alarmSnoozeUntil == nil ? 0.5 : 1)
            }
            .padding(.top)
            .disabled(store.state.latestSensorGlucose == nil)
            .buttonStyle(.plain)
        }
    }
}
