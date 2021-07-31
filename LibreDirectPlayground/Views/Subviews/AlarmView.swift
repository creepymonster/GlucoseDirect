//
//  AlarmView.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 19.07.21.
//

import SwiftUI

struct AlarmView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        GroupBox(label: Text("Alarm Settings").padding(.bottom).foregroundColor(.accentColor)) {
            NumberSelectorView(key: LocalizedString("Lower Limit", comment: ""), value: store.state.alarmLow, completionHandler: { (value) -> Void in
                store.dispatch(.setAlarmLow(value: value))
            })

            NumberSelectorView(key: LocalizedString("Upper Limit", comment: ""), value: store.state.alarmHigh, completionHandler: { (value) -> Void in
                store.dispatch(.setAlarmHigh(value: value))
            })

            DateSelectorView(key: LocalizedString("Snooze Until", comment: ""), value: store.state.alarmSnoozeUntil, completionHandler: { (value) -> Void in
                store.dispatch(.setAlarmSnoozeUntil(value: value))
            })
        }
    }
}

struct AlarmView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            AlarmView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
