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
            header: Text(LocalizedString("Alarm Settings"))
                .foregroundColor(.accentColor)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
        ) {
            NumberSelectorView(key: LocalizedString("Lower Limit", comment: ""), value: store.state.alarmLow, step: 5, displayValue: store.state.alarmLow.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value -> Void in
                store.dispatch(.setAlarmLow(value: value))
            }

            NumberSelectorView(key: LocalizedString("Upper Limit", comment: ""), value: store.state.alarmHigh, step: 5, displayValue: store.state.alarmHigh.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value -> Void in
                store.dispatch(.setAlarmHigh(value: value))
            }
        }
    }
}

// MARK: - AlarmView_Previews

struct AlarmView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            AlarmSettingsView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
