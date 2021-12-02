//
//  SettingsView.swift
//  LibreDirect
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            List {
                GlucoseSettingsView()
                NightscoutSettingsView()
                AlarmSettingsView()
                OtherSettings()
            }
        }
    }
}
