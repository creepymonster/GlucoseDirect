//
//  ContentView.swift
//  LibreDirect
//

import CoreNFC
import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var contentView: some View {
        TabView(selection: selectedView) {
            GlucoeOverviewView().tabItem {
                Label("Glucose overview", systemImage: "waveform.path.ecg")
            }.tag(1)

            GlucoseListView().tabItem {
                Label("Glucose list view", systemImage: "list.dash")
            }.tag(2)

            if store.state.isPaired, store.state.isConnectable || store.state.isDisconnectable, !store.state.glucoseValues.isEmpty {
                CalibrationsView().tabItem {
                    Label("Calibration view", systemImage: "tuningfork")
                }
                .badge(store.state.sensor?.customCalibration.count ?? 0)
                .tag(3)
            }

            SettingsView().tabItem {
                Label("Settings view", systemImage: "gearshape")
            }.tag(4)
        }
    }

    var errorView: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.ui.red)
                .frame(width: 320, height: 160)

            VStack {
                Text("Unfortunately, an NFC-enabled iPhone is required to use the app :'(")
            }
            .frame(width: 300, height: 140)
            .foregroundColor(Color.white)
        }.padding()
    }

    var body: some View {
#if targetEnvironment(simulator) || targetEnvironment(macCatalyst)
        contentView
#else
        if NFCTagReaderSession.readingAvailable {
            contentView
        } else {
            errorView
        }
#endif
    }

    // MARK: Private

    private var selectedView: Binding<Int> {
        Binding(
            get: { store.state.selectedView },
            set: { store.dispatch(.selectView(viewTag: $0)) }
        )
    }
}

// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
    static func createAppState() -> AppState {
        var state = PreviewAppState()
        state.selectedView = 4
        
        return state
    }
    
    static var previews: some View {
        let store = AppStore(initialState: createAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            ContentView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
