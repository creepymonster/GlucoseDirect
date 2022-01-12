//
//  AlarmSettingsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - AlarmSettingsView

struct AlarmSettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                HStack {
                    Text("Low glucose alarm")
                    Spacer()

                    Picker("", selection: selectedLowGlucoseAlarmSound) {
                        ForEach(NotificationSound.allCases, id: \.rawValue) { info in
                            Text(info.localizedString)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                HStack {
                    Text("High glucose alarm")
                    Spacer()

                    Picker("", selection: selectedHighGlucoseAlarmSound) {
                        ForEach(NotificationSound.allCases, id: \.rawValue) { info in
                            Text(info.localizedString)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                HStack {
                    Text("Connection alarm")
                    Spacer()

                    Picker("", selection: selectedConnectionAlarmSound) {
                        ForEach(NotificationSound.allCases, id: \.rawValue) { info in
                            Text(info.localizedString)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                HStack {
                    Text("Wearing time alarm")
                    Spacer()

                    Picker("", selection: selectedExpiringAlarmSound) {
                        ForEach(NotificationSound.allCases, id: \.rawValue) { info in
                            Text(info.localizedString)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                ToggleView(key: LocalizedString("Ignore mute"), value: store.state.ignoreMute) { value -> Void in
                    store.dispatch(.setIgnoreMute(enabled: value))
                }
            },
            header: {
                Label("Alarm Settings", systemImage: "alarm")
            }
        )
    }

    // MARK: Private

    private var selectedLowGlucoseAlarmSound: Binding<String> {
        Binding(
            get: { store.state.lowGlucoseAlarmSound.rawValue },
            set: {
                let sound = NotificationSound(rawValue: $0)!
                
                store.dispatch(.setLowGlucoseAlarmSound(sound: sound))
                NotificationService.shared.playSound(ignoreMute: true, sound: sound)
            }
        )
    }

    private var selectedHighGlucoseAlarmSound: Binding<String> {
        Binding(
            get: { store.state.highGlucoseAlarmSound.rawValue },
            set: {
                let sound = NotificationSound(rawValue: $0)!
                
                store.dispatch(.setHighGlucoseAlarmSound(sound: sound))
                NotificationService.shared.playSound(ignoreMute: true, sound: sound)
            }
        )
    }

    private var selectedConnectionAlarmSound: Binding<String> {
        Binding(
            get: { store.state.connectionAlarmSound.rawValue },
            set: {
                let sound = NotificationSound(rawValue: $0)!
                
                store.dispatch(.setConnectionAlarmSound(sound: sound))
                NotificationService.shared.playSound(ignoreMute: true, sound: sound)
            }
        )
    }

    private var selectedExpiringAlarmSound: Binding<String> {
        Binding(
            get: { store.state.expiringAlarmSound.rawValue },
            set: {
                let sound = NotificationSound(rawValue: $0)!
                
                store.dispatch(.setExpiringAlarmSound(sound: sound))
                NotificationService.shared.playSound(ignoreMute: true, sound: sound)
            }
        )
    }
}
