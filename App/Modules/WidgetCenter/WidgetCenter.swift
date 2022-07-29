//
//  Widget.swift
//  GlucoseDirectApp
//

import ActivityKit
import Combine
import Foundation
import WidgetKit

@available(iOS 16.0, *)
func widgetCenterMiddleware() -> Middleware<DirectState, DirectAction> {
    widgetCenterMiddleware(service: LazyService<ActivityGlucoseService>(initialization: {
        ActivityGlucoseService()
    }))
}

@available(iOS 16.0, *)
private func widgetCenterMiddleware(service: LazyService<ActivityGlucoseService>) -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            WidgetCenter.shared.reloadAllTimelines()

            guard state.glucoseLiveActivity else {
                break
            }

            guard let latestSensorGlucose = state.latestSensorGlucose else {
                break
            }

            Task {
                await service.value.stopAll(alarmLow: state.alarmLow, alarmHigh: state.alarmHigh, glucose: latestSensorGlucose, glucoseUnit: state.glucoseUnit)
                service.value.start(alarmLow: state.alarmLow, alarmHigh: state.alarmHigh, glucose: latestSensorGlucose, glucoseUnit: state.glucoseUnit)
            }
        case .setGlucoseUnit(unit: _):
            WidgetCenter.shared.reloadAllTimelines()
            
        case .setGlucoseLiveActivity(enabled: let enabled):
            guard let latestSensorGlucose = state.latestSensorGlucose else {
                break
            }
            
            if enabled {
                service.value.start(alarmLow: state.alarmLow, alarmHigh: state.alarmHigh, glucose: latestSensorGlucose, glucoseUnit: state.glucoseUnit)
            } else {
                Task {
                    await service.value.stopAll(alarmLow: state.alarmLow, alarmHigh: state.alarmHigh, glucose: latestSensorGlucose, glucoseUnit: state.glucoseUnit)
                }
            }

        case .setAppState(appState: let appState):
            guard appState == .active else {
                break
            }

            guard state.glucoseLiveActivity else {
                break
            }

            guard let latestSensorGlucose = state.latestSensorGlucose else {
                break
            }

            if service.value.restartRequired {
                Task {
                    await service.value.stopAll(alarmLow: state.alarmLow, alarmHigh: state.alarmHigh, glucose: latestSensorGlucose, glucoseUnit: state.glucoseUnit)
                }
            }

        case .addSensorGlucose(glucoseValues: _):
            guard state.glucoseLiveActivity else {
                break
            }

            guard let latestSensorGlucose = state.latestSensorGlucose else {
                break
            }

            if service.value.startRequired, state.appState == .active {
                service.value.start(alarmLow: state.alarmLow, alarmHigh: state.alarmHigh, glucose: latestSensorGlucose, glucoseUnit: state.glucoseUnit)

            } else {
                Task {
                    await service.value.update(alarmLow: state.alarmLow, alarmHigh: state.alarmHigh, glucose: latestSensorGlucose, glucoseUnit: state.glucoseUnit)
                }
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - ActivityGlucoseService

@available(iOS 16.0, *)
private class ActivityGlucoseService {
    // MARK: Lifecycle

    init() {
        DirectLog.info("Create ActivityGlucoseService")
    }

    // MARK: Internal

    var restartRequired: Bool {
        if let activityEnd = activityStop, Date() > activityEnd {
            return true
        }

        return false
    }

    var startRequired: Bool {
        return activity == nil
    }

    func start(alarmLow: Int, alarmHigh: Int, glucose: SensorGlucose, glucoseUnit: GlucoseUnit) {
            let activityAttributes = SensorGlucoseActivityAttributes()

            // Estimated delivery time is one hour from now.
            let initialContentState = getStatus(alarmLow: alarmLow, alarmHigh: alarmHigh, glucose: glucose, glucoseUnit: glucoseUnit)

            do {
                let activity = try Activity<SensorGlucoseActivityAttributes>.request(
                    attributes: activityAttributes,
                    contentState: initialContentState,
                    pushType: nil)

                self.activity = activity
                self.activityStop = Date() + 60 * 60
            } catch {}
    }

    func update(alarmLow: Int, alarmHigh: Int, glucose: SensorGlucose, glucoseUnit: GlucoseUnit) async {
            guard let activity = activity else {
                return
            }

            let updatedStatus = getStatus(alarmLow: alarmLow, alarmHigh: alarmHigh, glucose: glucose, glucoseUnit: glucoseUnit)
            await activity.update(using: updatedStatus)
    }

    func stop(alarmLow: Int, alarmHigh: Int, glucose: SensorGlucose, glucoseUnit: GlucoseUnit) async {
            guard let activity = activity else {
                return
            }

            let updatedStatus = getStatus(alarmLow: alarmLow, alarmHigh: alarmHigh, glucose: glucose, glucoseUnit: glucoseUnit)
            await activity.end(using: updatedStatus, dismissalPolicy: .immediate)

            self.activity = nil
            self.activityStop = nil
    }

    func stopAll(alarmLow: Int, alarmHigh: Int, glucose: SensorGlucose, glucoseUnit: GlucoseUnit) async {
            let updatedStatus = getStatus(alarmLow: alarmLow, alarmHigh: alarmHigh, glucose: glucose, glucoseUnit: glucoseUnit)
            let activityStream = Activity<SensorGlucoseActivityAttributes>.activityUpdates

            for await activity in activityStream {
                await activity.end(using: updatedStatus, dismissalPolicy: .immediate)
            }
    }

    // MARK: Private

    private var activity: Activity<SensorGlucoseActivityAttributes>?
    private var activityStop: Date?

    private func getStatus(alarmLow: Int, alarmHigh: Int, glucose: SensorGlucose, glucoseUnit: GlucoseUnit) -> SensorGlucoseActivityAttributes.GlucoseStatus {
        return SensorGlucoseActivityAttributes.GlucoseStatus(alarmLow: alarmLow, alarmHigh: alarmHigh, glucose: glucose, glucoseUnit: glucoseUnit)
    }
}
