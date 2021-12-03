//
//  AlarmSnoozeView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - SnoozeView

struct SnoozeView: View {
    @EnvironmentObject var store: AppStore

    var snoozeTime: String {
        if let localSnoozeTime = store.state.alarmSnoozeUntil?.localTime {
            return String(format: LocalizedString("%1$@ a clock"), localSnoozeTime)
        }

        return ""
    }
   
    var body: some View {
        DateSelectorView(key: LocalizedString("Snooze until"), value: store.state.alarmSnoozeUntil, displayValue: snoozeTime) { value -> Void in
            store.dispatch(.setAlarmSnoozeUntil(untilDate: value))
        }
    }
}
