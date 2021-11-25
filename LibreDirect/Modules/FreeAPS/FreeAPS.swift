//
//  FreeAPS.swift
//  LibreDirect
//

import Combine
import Foundation

func freeAPSMiddleware() -> Middleware<AppState, AppAction> {
    return freeAPSMiddleware(service: FreeAPSService())
}

private func freeAPSMiddleware(service: FreeAPSService) -> Middleware<AppState, AppAction> {
    return { _, action, _ in
        switch action {
        case .addGlucose(glucose: let glucose):
            service.addGlucose(glucoseValues: [glucose])

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - FreeAPSService

private class FreeAPSService {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    func addGlucose(glucoseValues: [Glucose]) {
        let freeAPSValues = glucoseValues.map { $0.toFreeAPS() }

        Log.info("FreeAPS, values: \(freeAPSValues)")

        guard let freeAPSJson = try? JSONSerialization.data(withJSONObject: freeAPSValues) else {
            return
        }

        Log.info("FreeAPS, json: \(freeAPSJson)")

        UserDefaults.appGroup.freeAPSLatestReadings = freeAPSJson
    }
}

private extension Glucose {
    func toFreeAPS() -> [String: Any] {
        let date = "/Date(" + Int64(floor(self.timestamp.toMillisecondsAsDouble() / 1000) * 1000).description + ")/"

        let freeAPSGlucose: [String: Any] = [
            "Value": self.glucoseValue,
            "DT": date,
            "direction": self.trend.toFreeAPS()
        ]

        return freeAPSGlucose
    }
}

private extension SensorTrend {
    func toFreeAPS() -> String {
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
