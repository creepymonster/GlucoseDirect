//
//  GarminSettings.swift
//  GlucoseDirectApp
//

import SwiftUI

// MARK: - GarminSettings

struct GarminSettings: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        Section(
            content: {
                ToggleView(key: LocalizedString("Server (Location required)"), value: store.state.httpServer) { value in
                    store.dispatch(.setHttpServer(enabled: value))
                }

                if store.state.httpServer {
                    let url = "http://localhost:\(DirectConfig.httpServerPort)/sgv.json"

                    Link(destination: URL(string: url)!, label: {
                        Text(url)
                    })
                    .lineLimit(1)
                    .truncationMode(.head)
                }
            },
            header: {
                Label("Garmin settings", systemImage: "person.badge.clock.fill")
            }
        )
    }
}

// MARK: - GarminSettings_Previews

struct GarminSettings_Previews: PreviewProvider {
    static var previews: some View {
        GarminSettings()
    }
}
