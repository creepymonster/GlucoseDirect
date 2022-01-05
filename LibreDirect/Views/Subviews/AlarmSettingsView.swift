//
//  AlarmSettingsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - AlarmSettingsView

struct AlarmSettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                ToggleView(key: LocalizedString("Glucose alarm", comment: ""), value: store.state.glucoseAlarm) { value -> Void in
                    if value {
                        store.dispatch(.setGlucoseAlarmSound(sound: .alarm))
                    } else {
                        store.dispatch(.setGlucoseAlarmSound(sound: .none))
                    }
                }

                ToggleView(key: LocalizedString("Wearing time alarm", comment: ""), value: store.state.expiringAlarm) { value -> Void in
                    if value {
                        store.dispatch(.setExpiringAlarmSound(sound: .expiring))
                    } else {
                        store.dispatch(.setExpiringAlarmSound(sound: .none))
                    }
                }

                ToggleView(key: LocalizedString("Connection alarm", comment: ""), value: store.state.connectionAlarm) { value -> Void in
                    if value {
                        store.dispatch(.setConnectionAlarmSound(sound: .alarm))
                    } else {
                        store.dispatch(.setConnectionAlarmSound(sound: .none))
                    }
                }
            },
            header: {
                Label("Alarm Settings", systemImage: "alarm")
            }
        )
    }
}
