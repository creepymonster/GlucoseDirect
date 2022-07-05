//
//  AlarmSnoozeView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - SnoozeView

struct SnoozeView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            DateSelectorView(key: LocalizedString("Snooze until"), value: store.state.alarmSnoozeUntil, displayValue: snoozeTime) { value in
                store.dispatch(.setAlarmSnoozeUntil(untilDate: value))
            }
        }
    }

    // MARK: Private

    private var snoozeTime: String {
        if let localSnoozeTime = store.state.alarmSnoozeUntil?.toLocalTime() {
            return localSnoozeTime
        }

        return ""
    }
}
