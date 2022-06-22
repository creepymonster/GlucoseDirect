//
//  CalendarExportSettings.swift
//  GlucoseDirect
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
                    store.dispatch(.requestAppleHealthAccess(enabled: value))
                }

                ToggleView(key: LocalizedString("Export to Apple Calendar"), value: store.state.appleCalendarExport) { value in
                    withAnimation {
                        store.dispatch(.requestAppleCalendarAccess(enabled: value))
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

                            ForEach(calendars, id: \.self) { cal in
                                Text(cal)
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

    private var calendars: [String] {
        EKEventStore().calendars(for: .event).map { $0.title }
    }

    private var selectedCalendar: Binding<String> {
        Binding(
            get: { store.state.selectedCalendarTarget ?? LocalizedString("Please select") },
            set: { store.dispatch(.selectCalendarTarget(id: $0)) }
        )
    }
}
