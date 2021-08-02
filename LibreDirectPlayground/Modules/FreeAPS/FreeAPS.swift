//
//  FreeAPS.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

func freeAPSMiddleware(service: FreeAPSService) -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .setSensorReading(readingUpdate: let readingUpdate):
            service.addGlucose(glucoseValues: [readingUpdate.lastGlucose])

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}

class FreeAPSService {
    func addGlucose(glucoseValues: [SensorGlucose]) {
        let freeAPSValues = glucoseValues.map { $0.toFreeAPS() }
        
        Log.info("FreeAPS, values: \(freeAPSValues)")

        guard let freeAPSJson = try? JSONSerialization.data(withJSONObject: freeAPSValues) else {
            return
        }
        
        Log.info("FreeAPS, json: \(freeAPSJson)")

        UserDefaults.appGroup.freeAPSLatestReadings = freeAPSJson
    }
}

fileprivate extension SensorGlucose {
    func toFreeAPS() -> [String: Any] {
        let date = "/Date(" + Int64(floor(self.timeStamp.toMillisecondsAsDouble() / 1000) * 1000).description + ")/"

        let freeAPSGlucose: [String: Any] = [
            "Value": self.glucoseFiltered,
            "DT": date,
            "direction": self.trend.toFreeAPS()
        ]

        return freeAPSGlucose
    }
}

fileprivate extension SensorTrend {
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
