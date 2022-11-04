//
//  GlucoseSettingsView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - GlucoseSettingsView

struct GlucoseSettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Section(
            content: {
                Picker("Glucose unit", selection: selectedGlucoseUnit) {
                    Text(GlucoseUnit.mgdL.localizedDescription).tag(GlucoseUnit.mgdL.rawValue)
                    Text(GlucoseUnit.mmolL.localizedDescription).tag(GlucoseUnit.mmolL.rawValue)
                }.pickerStyle(.menu)

                NumberSelectorView(key: LocalizedString("Lower limit"), value: store.state.alarmLow, step: 5, max: store.state.alarmHigh, displayValue: store.state.alarmLow.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value in
                    store.dispatch(.setAlarmLow(lowerLimit: value))
                }

                NumberSelectorView(key: LocalizedString("Upper limit"), value: store.state.alarmHigh, step: 5, min: store.state.alarmLow, displayValue: store.state.alarmHigh.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value in
                    store.dispatch(.setAlarmHigh(upperLimit: value))
                }

                Toggle("Normal glucose notification", isOn: normalGlucoseNotification).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))
                Toggle("Alarm glucose notification", isOn: alarmGlucoseNotification).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))

                if #available(iOS 16.1, *) {
                    Toggle("Glucose Live Activity", isOn: glucoseLiveActivity).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))
                }

                Toggle("Glucose read aloud", isOn: readGlucose).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))
            },
            header: {
                Label("Glucose settings", systemImage: "cross.case")
            }
        )
    }

    // MARK: Private

    private var normalGlucoseNotification: Binding<Bool> {
        Binding(
            get: { store.state.normalGlucoseNotification },
            set: { store.dispatch(.setNormalGlucoseNotification(enabled: $0)) }
        )
    }

    private var alarmGlucoseNotification: Binding<Bool> {
        Binding(
            get: { store.state.alarmGlucoseNotification },
            set: { store.dispatch(.setAlarmGlucoseNotification(enabled: $0)) }
        )
    }

    private var glucoseLiveActivity: Binding<Bool> {
        Binding(
            get: { store.state.glucoseLiveActivity },
            set: { store.dispatch(.setGlucoseLiveActivity(enabled: $0)) }
        )
    }

    private var readGlucose: Binding<Bool> {
        Binding(
            get: { store.state.readGlucose },
            set: { store.dispatch(.setReadGlucose(enabled: $0)) }
        )
    }

    private var selectedGlucoseUnit: Binding<String> {
        Binding(
            get: { store.state.glucoseUnit.rawValue },
            set: { store.dispatch(.setGlucoseUnit(unit: GlucoseUnit(rawValue: $0)!)) }
        )
    }
}
