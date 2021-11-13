//
//  ContentView.swift
//  LibreDirect
//

import CoreNFC
import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var contentView: some View {
        ScrollView {
            Group {
                ActionsView()
                GlucoseView()
                SnoozeView()

                ChartView()
                SensorView()
                CalibrationView()

                AlarmSettingsView()
                GlucoseSettingsView()
                NightscoutSettingsView()

            }.padding([.horizontal, .bottom])
        }
    }

    var errorView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.red, lineWidth: 0)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color.red))
                .frame(width: 320, height: 120)
                .clipped()

            VStack {
                Text("Sorry, an NFC enabled iPhone is required to use LibreDirect :'(")
            }
            .frame(width: 300, height: 90)
            .foregroundColor(Color.white)
        }.padding()
    }

    var body: some View {
#if targetEnvironment(simulator)
        contentView
#else
        if NFCTagReaderSession.readingAvailable {
            contentView
        } else {
            errorView
        }
#endif
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
