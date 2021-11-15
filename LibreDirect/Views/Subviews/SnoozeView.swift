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
        DateSelectorView(key: LocalizedString("Snooze Until"), value: store.state.alarmSnoozeUntil, displayValue: snoozeTime) { value -> Void in
            store.dispatch(.setAlarmSnoozeUntil(value: value))
        }
    }
}

// MARK: - SnoozeView_Previews

struct SnoozeView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            SnoozeView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
