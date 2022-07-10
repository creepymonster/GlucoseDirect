//
//  ContentView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        TabView(selection: selectedView) {
            OverviewView().tabItem {
                Label("Glucose overview", systemImage: "waveform.path.ecg")
            }.tag(1)

            ListsView().tabItem {
                Label("Glucose list view", systemImage: "list.dash")
            }.tag(2)

            if store.state.isConnectionPaired && store.state.hasGlucoseValues && store.state.isConnectable || store.state.isDisconnectable {
                CalibrationsView().tabItem {
                    Label("Calibration view", systemImage: "tuningfork")
                }.tag(3)
            }

            SettingsView().tabItem {
                Label("Settings view", systemImage: "gearshape")
            }.tag(4)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background, store.state.preventScreenLock {
                store.dispatch(.setPreventScreenLock(enabled: false))
            }
        }
        .onAppear {
            let apparence = UITabBarAppearance()
            apparence.configureWithOpaqueBackground()

            UITabBar.appearance().scrollEdgeAppearance = apparence
        }.animation(.default, value: store.state.selectedView)
    }

    // MARK: Private

    private var selectedView: Binding<Int> {
        Binding(
            get: { store.state.selectedView },
            set: { store.dispatch(.selectView(viewTag: $0)) }
        )
    }
}
