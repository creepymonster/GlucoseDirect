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
            }.tag(DirectConfig.overviewViewTag)

            ListsView().tabItem {
                Label("Glucose list view", systemImage: "list.dash")
            }.tag(DirectConfig.listsViewTag)

            if store.state.isConnectionPaired && !store.state.sensorGlucoseHistory.isEmpty && store.state.isConnectable || store.state.isDisconnectable {
                CalibrationsView().tabItem {
                    Label("Calibration view", systemImage: "tuningfork")
                }.tag(DirectConfig.calibrationsViewTag)
            }

            SettingsView().tabItem {
                Label("Settings view", systemImage: "gearshape")
            }.tag(DirectConfig.settingsViewTag)
        }
        .onChange(of: scenePhase) { newPhase in
            if store.state.appState != newPhase {
                store.dispatch(.setAppState(appState: newPhase))
            }
            
            if newPhase == .background, store.state.preventScreenLock {
                store.dispatch(.setPreventScreenLock(enabled: false))
            }
        }
        .onAppear {
            DirectLog.info("onAppear()")
            
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
