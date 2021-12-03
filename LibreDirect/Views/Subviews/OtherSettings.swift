//
//  OtherSettings.swift
//  LibreDirect
//

import SwiftUI

struct OtherSettings: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        Section(
            content: {
                ToggleView(key: LocalizedString("Glucose badge"), value: store.state.glucoseBadge) { value -> Void in
                    store.dispatch(.setGlucoseBadge(enabled: value))
                }
            },
            header: {
                Label("Other Settings", systemImage: "flag.badge.ellipsis")
            }
        )
    }
}

struct OtherSettings_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            OtherSettings().environmentObject(store).preferredColorScheme($0)
        }
    }
}
