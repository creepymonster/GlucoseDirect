//
//  AdditionalSettings.swift
//  GlucoseDirectApp
//
//  Created by Reimar Metzen on 16.01.23.
//

import SwiftUI

struct AdditionalSettingsView: View {
    @EnvironmentObject var store: DirectStore
    
    var body: some View {
        Section(
            content: {
                if DirectConfig.showSmoothedGlucose {
                    Toggle("Show smoothed glucose", isOn: showSmoothedGlucose).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))
                }
                
                if DirectConfig.showInsulinInput {
                    Toggle("Show insulin input", isOn: showInsulinInput).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))
                }
            },
            header: {
                Label("Additional settings", systemImage: "gearshape")
            }
        )
    }
    
    private var showSmoothedGlucose: Binding<Bool> {
        Binding(
            get: { store.state.showSmoothedGlucose },
            set: { store.dispatch(.setShowSmoothedGlucose(enabled: $0)) }
        )
    }
    
    private var showInsulinInput: Binding<Bool> {
        Binding(
            get: { store.state.showInsulinInput },
            set: { store.dispatch(.setShowInsulinInput(enabled: $0)) }
        )
    }
}
