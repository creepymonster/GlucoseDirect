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
                ToggleView(key: LocalizedString("Alarm Enabled", comment: ""), value: store.state.alarm) { value -> Void in
                    store.dispatch(.setAlarm(enabled: value))
                }
                
                if store.state.alarm {
                    NumberSelectorView(key: LocalizedString("Lower Limit", comment: ""), value: store.state.alarmLow, step: 5, displayValue: store.state.alarmLow.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value -> Void in
                        store.dispatch(.setAlarmLow(lowerLimit: value))
                    }
                    
                    NumberSelectorView(key: LocalizedString("Upper Limit", comment: ""), value: store.state.alarmHigh, step: 5, displayValue: store.state.alarmHigh.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value -> Void in
                        store.dispatch(.setAlarmHigh(upperLimit: value))
                    }
                }
            },
            header: {
                Label("Alarm Settings", systemImage: "alarm")
            }
        )
    }
}
