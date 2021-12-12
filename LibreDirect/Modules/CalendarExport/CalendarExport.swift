//
//  CalendarExport.swift
//  LibreDirect
//

import Combine
import EventKit
import Foundation

func calendarExportMiddleware() -> Middleware<AppState, AppAction> {
    return calendarExportMiddleware(service: CalendarExportService())
}

func calendarExportMiddleware(service: CalendarExportService) -> Middleware<AppState, AppAction> {
    return { store, action, _ in
        switch action {
        case .setCalendarExport(enabled: let enabled):
            if enabled {
                service.requestAccess { granted in
                    if !granted {
                        store.dispatch(.setCalendarExport(enabled: false))
                    }
                }
            } else {
                store.dispatch(.selectCalendarTarget(id: nil))
            }

        case .addGlucose(glucose: let glucose):
            guard store.state.calendarExport, let calendarTarget = store.state.selectedCalendarTarget, glucose.type == .cgm else {
                break
            }

            service.createGlucoseEvent(calendarTarget: calendarTarget, glucose: glucose, glucoseUnit: store.state.glucoseUnit)

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - CalendarExportService

typealias CalendarExportHandler = (_ granted: Bool) -> Void

// MARK: - CalendarExportService

class CalendarExportService {
    // MARK: Internal

    lazy var eventStore: EKEventStore = {
        EKEventStore()
    }()

    func requestAccess(completionHandler: @escaping CalendarExportHandler) {
        eventStore.requestAccess(to: EKEntityType.event, completion: { granted, error in
            if granted, error == nil {
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        })
    }

    func clearGlucoseEvents() {
        guard let calendar = calendar else {
            return
        }

        let predicate = eventStore.predicateForEvents(
            withStart: Date(timeIntervalSinceNow: -24 * 3600),
            end: Date(),
            calendars: [calendar]
        )

        let events = eventStore.events(matching: predicate)

        for event in events {
            if event.url == AppConfig.AppSchemaUrl {
                do {
                    try eventStore.remove(event, span: .thisEvent)
                } catch {
                    AppLog.error("Cannot remove calendar event: \(error)")
                }
            }
        }
    }

    func createGlucoseEvent(calendarTarget: String, glucose: Glucose, glucoseUnit: GlucoseUnit) {
        if calendar == nil || calendar?.title != calendarTarget {
            calendar = eventStore.calendars(for: .event).first(where: { $0.title == calendarTarget })
        }

        guard let calendar = calendar else {
            return
        }
        
        clearGlucoseEvents()
        
        guard let glucoseValue = glucose.glucoseValue else {
            return
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "\(glucose.trend.description) \(glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true)) (\(glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) ?? ""))"
        event.calendar = calendar
        event.url = AppConfig.AppSchemaUrl
        event.startDate = Date()
        event.endDate = Date(timeIntervalSinceNow: 60 * 10)

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            AppLog.error("Cannot create calendar event: \(error)")
        }
    }

    // MARK: Private

    private var calendar: EKCalendar?
}
