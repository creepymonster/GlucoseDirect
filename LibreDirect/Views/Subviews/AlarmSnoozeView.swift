//
//  AlarmSnoozeView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 27.08.21.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI

// MARK: - AlarmSnoozeView

struct AlarmSnoozeView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        GroupBox {
            DateSelectorView(key: LocalizedString("Snooze Until", comment: ""), value: store.state.alarmSnoozeUntil, displayValue: store.state.alarmSnoozeUntil?.localTime) { value -> Void in
                store.dispatch(.setAlarmSnoozeUntil(value: value))
            }
        }
    }
}

// MARK: - AlarmSnooze_Previews

struct AlarmSnooze_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            AlarmSnoozeView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
