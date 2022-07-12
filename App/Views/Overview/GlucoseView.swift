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
        if let latestGlucose = store.state.latestSensorGlucose {
            ZStack(alignment: .bottom) {
                Group {
                    VStack(alignment: .center, spacing: 0) {
                        HStack(alignment: .lastTextBaseline) {
                            Text(latestGlucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit))
                                .font(.system(size: 96))

                            VStack(alignment: .center) {
                                Text(latestGlucose.trend.description)
                                    .font(.system(size: 52))
                                    .bold()

                                Text(store.state.glucoseUnit.localizedString)
                                    .foregroundStyle(Color.primary)
                            }.padding(.leading, 5)
                        }.foregroundColor(getGlucoseColor(glucose: latestGlucose))

                        HStack(spacing: 20) {
                            Spacer()
                            Text(latestGlucose.timestamp.toLocalTime())
                            Spacer()

                            if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: store.state.glucoseUnit), latestGlucose.trend != .unknown {
                                Text(minuteChange)
                            } else {
                                Text("?".asMinuteChange())
                            }

                            Spacer()
                        }
                        .padding(.bottom)
                        .opacity(0.5)
                    }.frame(maxWidth: .infinity)
//                        VStack(alignment: .center, spacing: 0) {
//                            Image(systemName: "exclamationmark.triangle")
//                                .foregroundColor(Color.ui.red)
//                                .font(.system(size: 112))
//
//                            Text("Attention, the sensor sends faulty values. Please wait 10 minutes.")
//                                .padding(.top)
//                        }
                }.padding(.bottom, 30)

                HStack {
                    Button(action: {
                        store.dispatch(.setPreventScreenLock(enabled: !store.state.preventScreenLock))
                    }, label: {
                        if store.state.preventScreenLock {
                            Image(systemName: "lock.slash")
                            Text("No screen lock")
                        } else {
                            Image(systemName: "lock")
                        }
                    })
                    .opacity(store.state.preventScreenLock ? 1 : 0.5)

                    Spacer()

                    if store.state.alarmSnoozeUntil != nil {
                        Button(action: {
                            store.dispatch(.setAlarmSnoozeUntil(untilDate: nil))
                        }, label: {
                            Image(systemName: "xmark")
                        })
                        .opacity(0.5)
                    }

                    Button(action: {
                        let date = (store.state.alarmSnoozeUntil ?? Date()).toRounded(on: 1, .minute)
                        let nextDate = Calendar.current.date(byAdding: .minute, value: 60, to: date)

                        store.dispatch(.setAlarmSnoozeUntil(untilDate: nextDate))
                    }, label: {
                        if let alarmSnoozeUntil = store.state.alarmSnoozeUntil {
                            Text(alarmSnoozeUntil.toLocalTime())
                            Image(systemName: "speaker.slash")
                        } else {
                            Image(systemName: "speaker.wave.2")
                        }
                    })
                    .opacity(store.state.alarmSnoozeUntil == nil ? 0.5 : 1)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 5)
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
