//
//  ConnectionView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ConnectionView

struct ConnectionView: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        Section(
            content: {
                ConnectionActionsView()
            },
            header: {
                Label("Sensor connection", systemImage: "rectangle.connected.to.line.below")
            }
        )
    }
}
