//
//  CalendarExport.swift
//  GlucoseDirect
//

import Combine
import EventKit
import Foundation

func appleCalendarExportMiddleware() -> Middleware<DirectState, DirectAction> {
    return appleCalendarExportMiddleware(service: LazyService<AppleCalendarExportService>(initialization: {
        AppleCalendarExportService()
    }))
}

private func appleCalendarExportMiddleware(service: LazyService<AppleCalendarExportService>) -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .requestAppleCalendarAccess(enabled: let enabled):
            if enabled {
                return Future<DirectAction, DirectError> { promise in
                    service.value.requestAccess { granted in
                        if !granted {
                            promise(.failure(.withMessage("Calendar access declined")))

                        } else {
                            promise(.success(.setAppleCalendarExport(enabled: true)))
                        }
                    }
                }.eraseToAnyPublisher()

            } else {
                // clear events on disable
                service.value.clearGlucoseEvents()

                return Just(DirectAction.setAppleCalendarExport(enabled: false))
                    .setFailureType(to: DirectError.self)
                    .eraseToAnyPublisher()
            }

        case .setConnectionState(connectionState: let connectionState):
            guard state.appleCalendarExport else {
                DirectLog.info("Guard: state.calendarExport disabled")
                break
            }

            guard let calendarTarget = state.selectedCalendarTarget else {
                DirectLog.info("Guard: state.selectedCalendarTarget is nil")
                break
            }

            if connectionState == .connected {
                service.value.clearGlucoseEvents()
            } else {
                service.value.addConnectionState(calendarTarget: calendarTarget, connectionState: connectionState, connectionError: state.connectionError)
            }

        case .addSensorGlucose(glucoseValues: let glucoseValues):
            guard state.appleCalendarExport else {
                DirectLog.info("Guard: state.calendarExport disabled")
                break
            }

            guard let calendarTarget = state.selectedCalendarTarget else {
                DirectLog.info("Guard: state.selectedCalendarTarget is nil")
                break
            }

            guard let glucose = glucoseValues.last else {
                break
            }

            service.value.addSensorGlucose(calendarTarget: calendarTarget, glucose: glucose, glucoseUnit: state.glucoseUnit, sensorInterval: Double(state.sensorInterval))

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - CalendarExportService

typealias CalendarExportHandler = (_ granted: Bool) -> Void

// MARK: - AppleCalendarExportService

private class AppleCalendarExportService {
    // MARK: Lifecycle

    init() {
        DirectLog.info("Create AppleCalendarExportService")
    }

    // MARK: Internal

    lazy var eventStore: EKEventStore = .init()

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
            if event.url == DirectConfig.appSchemaURL {
                do {
                    try eventStore.remove(event, span: .thisEvent)
                } catch {
                    DirectLog.error("Cannot remove calendar event: \(error)")
                }
            }
        }
    }

    func addConnectionState(calendarTarget: String, connectionState: SensorConnectionState, connectionError: String?) {
        addCalendarEntry(calendarTarget: calendarTarget, timestamp: Date(), durationMinutes: 120, title: connectionState.localizedDescription, location: connectionError)
    }

    func addSensorGlucose(calendarTarget: String, glucose: SensorGlucose, glucoseUnit: GlucoseUnit, sensorInterval: Double) {
        addCalendarEntry(calendarTarget: calendarTarget, timestamp: glucose.timestamp, durationMinutes: 15, title: "\(glucose.trend.description) \(glucose.glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true))", location: glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit))
    }

    // MARK: Private

    private var calendar: EKCalendar?

    private func addCalendarEntry(calendarTarget: String, timestamp: Date, durationMinutes: Double, title: String, location: String? = nil) {
        if calendar == nil || calendar?.title != calendarTarget {
            calendar = eventStore.calendars(for: .event).first(where: { $0.title == calendarTarget })
        }

        guard let calendar = calendar else {
            return
        }

        clearGlucoseEvents()

        let event = EKEvent(eventStore: eventStore)
        event.title = title

        if let location = location {
            event.location = location
        }

        event.calendar = calendar
        event.url = DirectConfig.appSchemaURL
        event.startDate = timestamp
        event.endDate = timestamp + durationMinutes * 60

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            DirectLog.error("Cannot create calendar event: \(error)")
        }
    }

    private func findEvent() -> EKEvent? {
        guard let calendar = calendar else {
            return nil
        }

        let predicate = eventStore.predicateForEvents(
            withStart: Date(timeIntervalSinceNow: -24 * 3600),
            end: Date(),
            calendars: [calendar]
        )

        let events = eventStore.events(matching: predicate)

        for event in events {
            if event.url == DirectConfig.appSchemaURL {
                return event
            }
        }

        return nil
    }
}
