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
        if let latestGlucose = store.state.selectedGlucose ?? store.state.latestGlucose {
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
                            }.foregroundColor(getGlucoseColor(glucose: latestGlucose))

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
                    if store.state.selectedGlucose == nil {
                        Group {
                            Image(systemName: "lock.slash")
                                .font(.headline)
                                .opacity(store.state.preventScreenLock ? 1 : 0.25)

                            if store.state.preventScreenLock {
                                Text("No screen lock")
                            }
                        }.onTapGesture {
                            withAnimation {
                                store.dispatch(.setPreventScreenLock(enabled: !store.state.preventScreenLock))
                            }
                        }

                        Spacer()

                        Group {
                            if store.state.alarmSnoozeUntil != nil {
                                Image(systemName: "xmark")
                                    .opacity(0.25)
                                    .onTapGesture {
                                        withAnimation {
                                            store.dispatch(.setAlarmSnoozeUntil(untilDate: nil))
                                        }
                                    }
                            }

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
                                let date = (store.state.alarmSnoozeUntil ?? Date()).toRounded(on: 1, .minute)
                                let nextDate = Calendar.current.date(byAdding: .minute, value: 60, to: date)

                                withAnimation {
                                    store.dispatch(.setAlarmSnoozeUntil(untilDate: nextDate))
                                }
                            }
                            .onLongPressGesture {
                                withAnimation {
                                    store.dispatch(.setAlarmSnoozeUntil(untilDate: nil))
                                }
                            }
                        }
                    } else {
                        Text("History")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .font(.footnote)
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .foregroundStyle(Color.ui.blue)
                                    .opacity(0.5)
                            )
                    }
                }.padding(.bottom, 5)
            }
        }
    }

    // MARK: Private

    private func isAlarm(glucose: Glucose) -> Bool {
        if let glucoseValue = glucose.glucoseValue, glucoseValue < store.state.alarmLow || glucoseValue > store.state.alarmHigh {
            return true
        }

        return false
    }

    private func getGlucoseColor(glucose: Glucose) -> Color {
        if isAlarm(glucose: glucose) {
            return Color.ui.red
        }

        return Color.primary
    }
}
