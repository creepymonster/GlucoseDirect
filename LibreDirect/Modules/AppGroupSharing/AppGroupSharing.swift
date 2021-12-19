//
//  FreeAPS.swift
//  LibreDirect
//

import Combine
import Foundation

func appGroupSharingMiddleware() -> Middleware<AppState, AppAction> {
    return appGroupSharingMiddleware(service: AppGroupSharingService())
}

private func appGroupSharingMiddleware(service: AppGroupSharingService) -> Middleware<AppState, AppAction> {
    return { _, action, _ in
        switch action {
        case .disconnectSensor:
            service.clearGlucoseValues()

        case .pairSensor:
            service.clearGlucoseValues()

        case .addGlucoseValues(glucoseValues: let glucoseValues):
            guard let glucose = glucoseValues.last else {
                break
            }

            service.addGlucose(glucoseValues: [glucose])

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - AppGroupSharingService

private class AppGroupSharingService {
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
            "Trend": trend.toFreeAPS(),
            "DT": date,
            "direction": trend.toFreeAPSX(),
            "from": AppConfig.projectName
        ]

        return freeAPSGlucose
    }
}

private extension SensorTrend {
    func toFreeAPS() -> Int {
        switch self {
        case .rapidlyRising:
            return 1
        case .fastRising:
            return 2
        case .rising:
            return 3
        case .constant:
            return 4
        case .falling:
            return 5
        case .fastFalling:
            return 6
        case .rapidlyFalling:
            return 7
        case .unknown:
            return 0
        }
    }

    func toFreeAPSX() -> String {
        switch self {
        case .rapidlyRising:
            return "DoubleUp"
        case .fastRising:
            return "SingleUp"
        case .rising:
            return "FortyFiveUp"
        case .constant:
            return "Flat"
        case .falling:
            return "FortyFiveDown"
        case .fastFalling:
            return "SingleDown"
        case .rapidlyFalling:
            return "DoubleDown"
        case .unknown:
            return "NONE"
        }
    }
}
