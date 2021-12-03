//
//  GlucoseSettingsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - GlucoseSettingsView

struct GlucoseSettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                HStack {
                    Text(LocalizedString("Glucose unit"))
                    Spacer()

                    Picker(LocalizedString("Glucose unit"), selection: selectedGlucoseUnit) {
                        Text(GlucoseUnit.mgdL.localizedString).tag(GlucoseUnit.mgdL.rawValue)
                        Text(GlucoseUnit.mmolL.localizedString).tag(GlucoseUnit.mmolL.rawValue)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                NumberSelectorView(key: LocalizedString("Lower limit", comment: ""), value: store.state.alarmLow, step: 5, max: store.state.alarmHigh, displayValue: store.state.alarmLow.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value -> Void in
                    store.dispatch(.setAlarmLow(lowerLimit: value))
                }

                NumberSelectorView(key: LocalizedString("Upper limit", comment: ""), value: store.state.alarmHigh, step: 5, min: store.state.alarmLow, displayValue: store.state.alarmHigh.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value -> Void in
                    store.dispatch(.setAlarmHigh(upperLimit: value))
                }
            },
            header: {
                Label("Glucose settings", systemImage: "cross.case")
            }
        )
    }
    
    private var selectedGlucoseUnit: Binding<String> {
        Binding(
            get: { store.state.glucoseUnit.rawValue },
            set: { store.dispatch(.setGlucoseUnit(unit: GlucoseUnit(rawValue: $0)!)) }
        )
    }
}
