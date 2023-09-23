//
//  SensorConfiguration.swift
//  GlucoseDirectApp
//

import SwiftUI

struct SensorConnectionConfigurationView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        if !store.state.selectedConfiguration.isEmpty {
            Section(
                content: {
                    VStack() {
                        ForEach(store.state.selectedConfiguration, id: \.id) { entry in
                            VStack(alignment: .leading) {
                                Text(entry.name)
                                
                                if entry.isSecret {
                                    SecureInputView("", text: entry.value)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .submitLabel(.done)
                                } else {
                                    TextField("", text: entry.value)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                    }
                    .onSubmit(of: .text, {() -> Void in store.dispatch(.connectConnection)})
                },
                header: {
                    Label("Connection settings", systemImage: "app.connected.to.app.below.fill")
                }
            )
        }
    }
}
