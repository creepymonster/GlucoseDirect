//
//  CalendarExportSettings.swift
//  LibreDirect
//

import EventKit
import SwiftUI

// MARK: - CalendarExportSettingsView

struct AppleExportSettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                ToggleView(key: LocalizedString("Export to Apple Health"), value: store.state.appleHealthExport) { value in
                    store.dispatch(.setAppleHealthExport(enabled: value))
                }

                ToggleView(key: LocalizedString("Export to Apple Calendar"), value: store.state.appleCalendarExport) { value in
                    withAnimation {
                        store.dispatch(.setAppleCalendarExport(enabled: value))
                    }
                }

                if store.state.appleCalendarExport {
                    HStack {
                        Text("Selected calendar")
                        Spacer()

                        Picker("", selection: selectedCalendar) {
                            if store.state.selectedCalendarTarget == nil {
                                Text("Please select")
                            }

                            ForEach(EKEventStore().calendars(for: .event), id: \.title) { cal in
                                Text(cal.title)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
            },
            header: {
                Label("Apple export settings", systemImage: "square.and.arrow.up")
            }
        )
    }

    // MARK: Private

    private var selectedCalendar: Binding<String> {
        Binding(
            get: { store.state.selectedCalendarTarget ?? LocalizedString("Please select") },
            set: { store.dispatch(.selectCalendarTarget(id: $0)) }
        )
    }
}
