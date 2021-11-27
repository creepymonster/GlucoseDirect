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
                ToggleView(key: LocalizedString("Glucose low/high", comment: ""), value: store.state.glucoseAlarm) { value -> Void in
                    store.dispatch(.setGlucoseAlarm(enabled: value))
                }
                
                ToggleView(key: LocalizedString("Lifetime ends", comment: ""), value: store.state.expiringAlarm) { value -> Void in
                    store.dispatch(.setExpiringAlarm(enabled: value))
                }
                
                ToggleView(key: LocalizedString("Connection issues", comment: ""), value: store.state.connectionAlarm) { value -> Void in
                    store.dispatch(.setConnectionAlarm(enabled: value))
                }
                
            },
            header: {
                Label("Alarm Settings", systemImage: "alarm")
            }
        )
    }
}
