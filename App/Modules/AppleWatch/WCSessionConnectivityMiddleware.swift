//
//  WCSessionConnectivityMiddleware.swift
//  GlucoseDirect
//

import Foundation
import Combine

func wcSessionConnectivityMiddleware() -> Middleware<DirectState, DirectAction> {
    return wcSessionConnectivityMiddleware(service: LazyService<WCSessionConnectivityService>(initialization: {
        WCSessionConnectivityService.shared
    }))
}


private func wcSessionConnectivityMiddleware(service: LazyService<WCSessionConnectivityService>) -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        
        case .addSensorGlucose(glucoseValues: let glucoseValues):
            guard let glucose = glucoseValues.last else {
                break
            }
            service.value.addSensorGlucose(glucoseValue: glucose)
        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}


extension WCSessionConnectivityService {
    /**
     Send sensor glucose to Apple Watch
     */
    func addSensorGlucose(glucoseValue: SensorGlucose) {
        send(glucoseValue)
    }
}
