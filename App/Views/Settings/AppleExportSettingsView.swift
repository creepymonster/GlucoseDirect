//
//  CalendarExportSettings.swift
//  GlucoseDirect
//

import EventKit
import SwiftUI

// MARK: - CalendarExportSettingsView

struct AppleExportSettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Section(
            content: {
                Toggle("Export to Apple Health", isOn: appleHealthExport).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))
                Toggle("Export to Apple Calendar", isOn: appleCalendarExport).toggleStyle(SwitchToggleStyle(tint: Color.ui.accent))

                if store.state.appleCalendarExport {
                    Picker("Selected calendar", selection: selectedCalendar) {
                        if store.state.selectedCalendarTarget == nil {
                            Text("Please select")
                        }

                        ForEach(calendars, id: \.self) { cal in
                            Text(cal)
                        }
                    }.pickerStyle(.menu)
                }
            },
            header: {
                Label("Apple export settings", systemImage: "square.and.arrow.up")
            }
        )
    }

    // MARK: Private

    private var calendars: [String] {
        EKEventStore().calendars(for: .event).map { $0.title }
    }

    private var appleHealthExport: Binding<Bool> {
        Binding(
            get: { store.state.appleHealthExport },
            set: { store.dispatch(.requestAppleHealthAccess(enabled: $0)) }
        )
    }

    private var appleCalendarExport: Binding<Bool> {
        Binding(
            get: { store.state.appleCalendarExport },
            set: { store.dispatch(.requestAppleCalendarAccess(enabled: $0)) }
        )
    }

    private var selectedCalendar: Binding<String> {
        Binding(
            get: { store.state.selectedCalendarTarget ?? LocalizedString("Please select") },
            set: { store.dispatch(.selectCalendarTarget(id: $0)) }
        )
    }
}
