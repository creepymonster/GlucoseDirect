//
//  GlucoseSettingsView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 02.08.21.
//

import SwiftUI
import LibreDirectLibrary

fileprivate extension Bool {
    var asGlucoseUnit: GlucoseUnit {
        if self == GlucoseUnit.mgdL.asBool {
            return GlucoseUnit.mgdL
        }
        
        return GlucoseUnit.mmolL
    }
}

fileprivate extension GlucoseUnit {
    var asBool: Bool {
        return self == .mmolL
    }
}

struct GlucoseSettingsView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        GroupBox(label: Text("Glucose Settings").padding(.bottom).foregroundColor(.accentColor)) {
            ToggleView(key: LocalizedBundleString("Glucose Unit", comment: ""), value: store.state.glucoseUnit.asBool, trueValue: true.asGlucoseUnit.description, falseValue: false.asGlucoseUnit.description, completionHandler: { (value) -> Void in
                store.dispatch(.setGlucoseUnit(value: value.asGlucoseUnit))
            })
        }
    }
}
