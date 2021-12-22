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
                    store.dispatch(.setGlucoseAlarm(enabled: value))
                }

                ToggleView(key: LocalizedString("Wearing time alarm", comment: ""), value: store.state.expiringAlarm) { value -> Void in
                    store.dispatch(.setExpiringAlarm(enabled: value))
                }

                ToggleView(key: LocalizedString("Connection alarm", comment: ""), value: store.state.connectionAlarm) { value -> Void in
                    store.dispatch(.setConnectionAlarm(enabled: value))
                }
            },
            header: {
                Label("Alarm Settings", systemImage: "alarm")
            }
        )
    }
}
