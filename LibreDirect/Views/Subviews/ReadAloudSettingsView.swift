//
//  ReadAloudSettingsView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - ReadAloudSettingsView

struct ReadAloudSettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                ToggleView(key: LocalizedString("Glucose read aloud"), value: store.state.readGlucose) { value -> Void in
                    store.dispatch(.setReadGlucose(enabled: value))
                }

                if store.state.readGlucose {
                    VStack(alignment: .leading) {
                        Text("Glucose values are read aloud:")
                            .fontWeight(.semibold)
                        
                        Text("Every 10 minutes")
                        Text("After disconnections")
                        Text("When the glucose trend changes")
                        Text("When a new alarm is triggered")
                    }
                    .foregroundColor(.gray)
                    .padding(.vertical, 5)
                }
            },
            header: {
                Label("Read aloud", systemImage: "ear")
            }
        )
    }
}

// MARK: - ReadAloudSettingsView_Previews

struct ReadAloudSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            ReadAloudSettingsView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
