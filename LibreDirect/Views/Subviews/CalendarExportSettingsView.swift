//
//  CalendarExportSettings.swift
//  LibreDirect
//

import EventKit
import SwiftUI

// MARK: - CalendarExportSettingsView

struct CalendarExportSettingsView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                ToggleView(key: LocalizedString("Calendar export enabled"), value: store.state.calendarExport) { value -> Void in
                    withAnimation {
                        store.dispatch(.setCalendarExport(enabled: value))
                    }
                }

                if store.state.calendarExport {
                    HStack {
                        Text(LocalizedString("Selected calendar"))
                        Spacer()

                        Picker(LocalizedString("Selected calendar"), selection: selectedCalendar) {
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
                Label("Calendar export", systemImage: "calendar")
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

// MARK: - CalendarExportSettings_Previews

struct CalendarExportSettings_Previews: PreviewProvider {
    static var previews: some View {
        CalendarExportSettingsView()
    }
}
