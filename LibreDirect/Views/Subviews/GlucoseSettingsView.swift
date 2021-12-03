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
                ToggleView(key: LocalizedString("Glucose unit", comment: ""), value: store.state.glucoseUnit.asBool, trueValue: true.asGlucoseUnit.description, falseValue: false.asGlucoseUnit.description) { value -> Void in
                    store.dispatch(.setGlucoseUnit(unit: value.asGlucoseUnit))
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
}

private extension Bool {
    var asGlucoseUnit: GlucoseUnit {
        if self == GlucoseUnit.mgdL.asBool {
            return GlucoseUnit.mgdL
        }

        return GlucoseUnit.mmolL
    }
}

private extension GlucoseUnit {
    var asBool: Bool {
        return self == .mmolL
    }
}
