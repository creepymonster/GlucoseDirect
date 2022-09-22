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
                HStack {
                    Text("Glucose unit")
                    Spacer()

                    Picker("", selection: selectedGlucoseUnit) {
                        Text(GlucoseUnit.mgdL.localizedDescription).tag(GlucoseUnit.mgdL.rawValue)
                        Text(GlucoseUnit.mmolL.localizedDescription).tag(GlucoseUnit.mmolL.rawValue)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                NumberSelectorView(key: LocalizedString("Lower limit"), value: store.state.alarmLow, step: 5, max: store.state.alarmHigh, displayValue: store.state.alarmLow.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value in
                    store.dispatch(.setAlarmLow(lowerLimit: value))
                }

                NumberSelectorView(key: LocalizedString("Upper limit"), value: store.state.alarmHigh, step: 5, min: store.state.alarmLow, displayValue: store.state.alarmHigh.asGlucose(unit: store.state.glucoseUnit, withUnit: true)) { value in
                    store.dispatch(.setAlarmHigh(upperLimit: value))
                }

                ToggleView(key: LocalizedString("Normal glucose notification"), value: store.state.normalGlucoseNotification) { value in
                    store.dispatch(.setNormalGlucoseNotification(enabled: value))
                }

                ToggleView(key: LocalizedString("Alarm glucose notification"), value: store.state.alarmGlucoseNotification) { value in
                    store.dispatch(.setAlarmGlucoseNotification(enabled: value))
                }

                if #available(iOS 16.1, *) {
                    ToggleView(key: LocalizedString("Glucose Live Activity"), value: store.state.glucoseLiveActivity) { value in
                        store.dispatch(.setGlucoseLiveActivity(enabled: value))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ToggleView(key: LocalizedString("Glucose read aloud"), value: store.state.readGlucose) { value in
                        store.dispatch(.setReadGlucose(enabled: value))
                    }

                    if store.state.readGlucose {
                        Group {
                            Text("Every 10 minutes")
                            Text("After disconnections")
                            Text("When the glucose trend changes")
                            Text("When a new alarm is triggered")
                        }
                        .font(.footnote)
                        .foregroundColor(.gray)
                    }
                }
            },
            header: {
                Label("Glucose settings", systemImage: "cross.case")
            }
        )
    }

    // MARK: Private

    private var selectedGlucoseUnit: Binding<String> {
        Binding(
            get: { store.state.glucoseUnit.rawValue },
            set: { store.dispatch(.setGlucoseUnit(unit: GlucoseUnit(rawValue: $0)!)) }
        )
    }
}
