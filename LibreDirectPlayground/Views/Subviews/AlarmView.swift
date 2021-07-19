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
        Divider().padding(.trailing)

        Section(header: HStack {
            Text("ALARMS").foregroundColor(.gray).font(.subheadline)
            Spacer()
        }) {
            KeyNumberEditorView(key: "Low", value: store.state.alarmLow, completionHandler: { (value) -> Void in
                store.dispatch(.setAlarmLow(value: value))
            })
            KeyNumberEditorView(key: "High", value: store.state.alarmHigh, completionHandler: { (value) -> Void in
                store.dispatch(.setAlarmHigh(value: value))
            })

            Button(action: {
                store.dispatch(.setAlarmSnooze)
            }) {
                KeyValueView(key: "Snooze", value: store.state.alarmSnoozeUntil?.localTime ?? "-")
            }
        }
    }
}

struct AlarmView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        NightscoutView().environmentObject(store)
    }
}
