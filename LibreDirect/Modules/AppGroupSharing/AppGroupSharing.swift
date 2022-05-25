//
//  FreeAPS.swift
//  LibreDirect
//

import Combine
import Foundation

func appGroupSharingMiddleware() -> Middleware<AppState, AppAction> {
    return appGroupSharingMiddleware(service: LazyService<AppGroupSharingService>(initialization: {
        AppGroupSharingService()
    }))
}

private func appGroupSharingMiddleware(service: LazyService<AppGroupSharingService>) -> Middleware<AppState, AppAction> {
    return { _, action, _ in
        switch action {
        case .disconnectSensor:
            service.value.clearGlucoseValues()

        case .pairSensor:
            service.value.clearGlucoseValues()

        case .addGlucoseValues(glucoseValues: let glucoseValues):
            guard let glucose = glucoseValues.last else {
                AppLog.info("Guard: glucoseValues.last is nil")
                break
            }

            service.value.addGlucose(glucoseValues: [glucose])

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - AppGroupSharingService

private class AppGroupSharingService {
    // MARK: Lifecycle

    init() {
        AppLog.info("Create AppGroupSharingService")
    }

    // MARK: Internal

    func clearGlucoseValues() {
        UserDefaults.shared.latestReadings = nil
    }

    func addGlucose(glucoseValues: [Glucose]) {
        let sharedValues = glucoseValues
            .map { $0.toFreeAPS() }
            .compactMap { $0 }

        if sharedValues.isEmpty {
            return
        }

        AppLog.info("Shared values, values: \(sharedValues)")

        guard let sharedValuesJson = try? JSONSerialization.data(withJSONObject: sharedValues) else {
            return
        }

        AppLog.info("Shared values, json: \(sharedValuesJson)")

        UserDefaults.shared.latestReadings = sharedValuesJson
    }
}

private extension Glucose {
    func toFreeAPS() -> [String: Any]? {
        guard let glucoseValue = glucoseValue else {
            return nil
        }

        let date = "/Date(" + Int64(floor(timestamp.toMillisecondsAsDouble() / 1000) * 1000).description + ")/"

        let freeAPSGlucose: [String: Any] = [
            "Value": glucoseValue,
            "Trend": trend.toNightscoutTrend(),
            "DT": date,
            "direction": trend.toNightscoutDirection(),
            "from": AppConfig.projectName
        ]

        return freeAPSGlucose
    }
}
