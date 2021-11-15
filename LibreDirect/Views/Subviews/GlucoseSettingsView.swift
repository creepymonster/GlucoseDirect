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
            header: Text(LocalizedString("Glucose Settings"))
                .foregroundColor(.accentColor)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
        ) {
            ToggleView(key: LocalizedString("Glucose Unit", comment: ""), value: store.state.glucoseUnit.asBool, trueValue: true.asGlucoseUnit.description, falseValue: false.asGlucoseUnit.description) { value -> Void in
                store.dispatch(.setGlucoseUnit(value: value.asGlucoseUnit))
            }
        }
    }
}

// MARK: - GlucoseSettingsView_Previews

struct GlucoseSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            GlucoseSettingsView().environmentObject(store).preferredColorScheme($0)
        }
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
