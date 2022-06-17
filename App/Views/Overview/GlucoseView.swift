//
//  GlucoseView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - GlucoseView

struct GlucoseView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
        if let latestGlucose = store.state.latestGlucose {
            ZStack(alignment: .bottom) {
                Group {
                    if let glucoseValue = latestGlucose.glucoseValue, !latestGlucose.isFaultyGlucose {
                        VStack(alignment: .center, spacing: 0) {
                            HStack(alignment: .lastTextBaseline) {
                                Text(glucoseValue.asGlucose(unit: store.state.glucoseUnit))
                                    .font(.system(size: 96))

                                VStack(alignment: .leading) {
                                    Text(latestGlucose.trend.description).font(.system(size: 48))
                                    Text(store.state.glucoseUnit.localizedString)
                                }
                            }.foregroundColor(glucoseForegroundColor)

                            if let minuteChange = latestGlucose.minuteChange?.asMinuteChange(glucoseUnit: store.state.glucoseUnit), latestGlucose.trend != .unknown {
                                HStack(spacing: 20) {
                                    Spacer()
                                    Text(String(format: LocalizedString("%1$@ a clock"), latestGlucose.timestamp.toLocalTime()))
                                    Spacer()
                                    Text(minuteChange)
                                    Spacer()
                                }.padding(.bottom)
                            }
                        }
                    } else {
                        VStack(alignment: .center, spacing: 0) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(Color.ui.red)
                                .font(.system(size: 112))

                            Text("Attention, the sensor sends faulty values. Please wait 10 minutes.")
                                .padding(.top)
                        }
                    }
                }.padding(.bottom, 30)

                HStack {
                    Image(systemName: "lock.slash")
                        .font(.headline)
                        .opacity(store.state.preventScreenLock ? 1 : 0.25)
                        .onTapGesture {
                            store.dispatch(.setPreventScreenLock(enabled: !store.state.preventScreenLock))
                        }

                    Spacer()

                    Group {
                        if let alarmSnoozeUntil = store.state.alarmSnoozeUntil {
                            Text(String(format: LocalizedString("%1$@ a clock"), alarmSnoozeUntil.toLocalTime()))
                            Image(systemName: "speaker.slash")
                                .font(.headline)
                        } else {
                            Image(systemName: "speaker.slash")
                                .font(.headline)
                        }
                    }
                    .opacity(store.state.alarmSnoozeUntil == nil ? 0.25 : 1)
                    .onTapGesture {
                        let date = (store.state.alarmSnoozeUntil ?? Date()).toRounded(on: 15, .minute)
                        let nextDate = Calendar.current.date(byAdding: .minute, value: 30, to: date)

                        store.dispatch(.setAlarmSnoozeUntil(untilDate: nextDate))
                    }
                    .onLongPressGesture {
                        store.dispatch(.setAlarmSnoozeUntil(untilDate: nil))
                    }
                }.padding(.bottom, 5)
            }
        }
    }

    // MARK: Private

    private var isAlarm: Bool {
        if let glucose = store.state.latestSensorGlucose, let glucoseValue = glucose.glucoseValue, glucoseValue < store.state.alarmLow || glucoseValue > store.state.alarmHigh {
            return true
        }

        return false
    }

    private var glucoseForegroundColor: Color {
        if isAlarm {
            return Color.ui.red
        }

        return Color.primary
    }
}
