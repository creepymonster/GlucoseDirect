//
//  AlarmSnoozeView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - SnoozeView

struct SnoozeView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            DateSelectorView(key: LocalizedString("Snooze until"), value: store.state.alarmSnoozeUntil, displayValue: snoozeTime) { value -> Void in
                store.dispatch(.setAlarmSnoozeUntil(untilDate: value))
            }
        }
    }

    // MARK: Private

    private var snoozeTime: String {
        if let localSnoozeTime = store.state.alarmSnoozeUntil?.toLocalTime() {
            return String(format: LocalizedString("%1$@ a clock"), localSnoozeTime)
        }

        return ""
    }
}
