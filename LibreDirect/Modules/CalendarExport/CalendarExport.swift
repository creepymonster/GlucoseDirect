//
//  CalendarExport.swift
//  LibreDirect
//

import Combine
import EventKit
import Foundation

func calendarExportMiddleware() -> Middleware<AppState, AppAction> {
    return calendarExportMiddleware(service: {
        CalendarExportService()
    }())
}

func calendarExportMiddleware(service: CalendarExportService) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .setCalendarExport(enabled: let enabled):
            if enabled {
                return Future<AppAction, AppError> { promise in
                    service.requestAccess { granted in
                        if !granted {
                            promise(.success(.setCalendarExport(enabled: false)))

                        } else {
                            promise(.failure(.withMessage("Calendar access declined")))
                        }
                    }
                }.eraseToAnyPublisher()

            } else {
                // clear events on disable
                service.clearGlucoseEvents()

                return Just(AppAction.selectCalendarTarget(id: nil))
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }

        case .addGlucoseValues(glucoseValues: let glucoseValues):
            guard state.calendarExport else {
                AppLog.info("Guard: state.calendarExport disabled")
                break
            }

            guard let glucose = glucoseValues.last else {
                AppLog.info("Guard: glucoseValues.last is nil")
                break
            }

            guard glucose.type == .cgm else {
                AppLog.info("Guard: glucose.type is not .cgm")
                break
            }

            guard let calendarTarget = state.selectedCalendarTarget else {
                AppLog.info("Guard: state.selectedCalendarTarget is nil")
                break
            }

            service.createGlucoseEvent(calendarTarget: calendarTarget, glucose: glucose, glucoseUnit: state.glucoseUnit)

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
            if event.url == AppConfig.appSchemaUrl {
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
        event.title = "\(glucose.trend.description) \(glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true))"

        if let minuteChange = glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
            event.location = minuteChange
        }

        event.calendar = calendar
        event.url = AppConfig.appSchemaUrl
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
