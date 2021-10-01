//
//  FreeAPS.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation
import Combine

public func freeAPSMiddleware() -> Middleware<AppState, AppAction> {
    return freeAPSMiddleware(service: FreeAPSService())
}

fileprivate func freeAPSMiddleware(service: FreeAPSService) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .setSensorReading(glucose: let glucose):
            service.addGlucose(glucoseValues: [glucose])

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}

fileprivate class FreeAPSService {
    func addGlucose(glucoseValues: [SensorGlucose]) {
        let freeAPSValues = glucoseValues.map { $0.toFreeAPS() }
        
        Log.info("FreeAPS, values: \(freeAPSValues)")

        guard let freeAPSJson = try? JSONSerialization.data(withJSONObject: freeAPSValues) else {
            return
        }
        
        Log.info("FreeAPS, json: \(freeAPSJson)")

        UserDefaults.appGroup.freeAPSLatestReadings = freeAPSJson
    }
    
    init() {
    }
}

fileprivate extension SensorGlucose {
    func toFreeAPS() -> [String: Any] {
        let date = "/Date(" + Int64(floor(self.timestamp.toMillisecondsAsDouble() / 1000) * 1000).description + ")/"

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
