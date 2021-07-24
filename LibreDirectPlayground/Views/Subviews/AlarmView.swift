//
//  AlarmView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 19.07.21.
//

import SwiftUI

struct AlarmView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        GroupBox(label:
            Text("ALARMS")
        ) {
            NumberSelectorView(key: "Low", value: store.state.alarmLow, completionHandler: { (value) -> Void in
                store.dispatch(.setAlarmLow(value: value))
            })

            NumberSelectorView(key: "High", value: store.state.alarmHigh, completionHandler: { (value) -> Void in
                store.dispatch(.setAlarmHigh(value: value))
            })

            DateSelectorView(key: "Snooze", value: store.state.alarmSnoozeUntil, completionHandler: { (value) -> Void in
                store.dispatch(.setAlarmSnoozeUntil(value: value))
            })
        }
    }
}

struct AlarmView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        AlarmView().environmentObject(store)
    }
}
