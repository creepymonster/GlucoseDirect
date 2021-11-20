//
//  ContentView.swift
//  LibreDirect
//

import CoreNFC
import SwiftUI

// MARK: - DataView

struct DataView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            ActionsView()

            List {
                GlucoseView().frame(maxWidth: .infinity)
                ChartView()
                SensorView()
            }
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            List {
                GlucoseSettingsView()
                AlarmSettingsView()
                NightscoutSettingsView()
            }
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var calibrationView: some View {
        VStack {
            List {
                CalibrationView() 
            }
        }
    }

    var contentView: some View {
        TabView(selection: selectedView) {
            DataView().tabItem {
                Label("Sensor readings", systemImage: "waveform.path.ecg")
            }.tag(1)

            if store.state.isPaired && !store.state.glucoseValues.isEmpty {
                calibrationView.tabItem {
                    Label("Calibration", systemImage: "tuningfork")
                }
                .badge(store.state.sensor?.customCalibration.count ?? 0)
                .tag(2)
            }

            SettingsView().tabItem {
                Label("Settings", systemImage: "gearshape")
            }.tag(3)
        }
    }

    var errorView: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.ui.red)
                .frame(width: 320, height: 160)

            VStack {
                Text("Sorry, an NFC enabled iPhone is required to use LibreDirect :'(")
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
            set: { store.dispatch(.selectView(value: $0)) }
        )
    }
}

// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            ContentView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
