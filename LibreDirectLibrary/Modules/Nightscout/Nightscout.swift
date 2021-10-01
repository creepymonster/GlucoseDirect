//
//  Nightscout.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21. 
//

import Foundation
import Combine

public func nightscoutMiddleware() -> Middleware<AppState, AppAction> {
    return nightscoutMiddleware(service: NightscoutService())
}

func nightscoutMiddleware(service: NightscoutService) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .setSensorReading(glucose: let glucose):
            guard store.state.nightscoutUpload else {
                break
            }
            
            let minutes = Calendar.current.component(.minute, from: glucose.timestamp)

            guard minutes % 5 == 0 else {
                break
            }

            let nightscoutHost = store.state.nightscoutHost
            let nightscoutApiSecret = store.state.nightscoutApiSecret

            guard !nightscoutHost.isEmpty else {
                break
            }

            guard !nightscoutApiSecret.isEmpty else {
                break
            }

            service.addGlucose(nightscoutHost: nightscoutHost.trimmingCharacters(in: CharacterSet(charactersIn: "/")), apiSecret: nightscoutApiSecret.toSha1(), glucoseValues: [glucose])

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}

class NightscoutService {
    func addGlucose(nightscoutHost: String, apiSecret: String, glucoseValues: [SensorGlucose]) {
        let nightscoutValues = glucoseValues.map { $0.toNightscout() }

        guard let nightscoutJson = try? JSONSerialization.data(withJSONObject: nightscoutValues) else {
            return
        }
        
        let session = URLSession.shared
        let url = URL(string: "\(nightscoutHost)/api/v1/entries")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiSecret, forHTTPHeaderField: "api-secret")

        let task = session.uploadTask(with: request, from: nightscoutJson) { data, response, error in
            if let error = error {
                Log.info("Nightscout: \(error.localizedDescription)")
            }
            
            if let response = response as? HTTPURLResponse {
                let status = response.statusCode
                if status == 401 {
                    Log.info("Nightscout: not authorized")
                }
            }
        }

        task.resume()
    }
    
    init() {
    }
}

fileprivate extension SensorGlucose {
    func toNightscout() -> [String: Any] {
        let nightscout: [String: Any] = [
            "_id": id,
            "device": "LibreDirect",
            "date": timestamp.toMillisecondsAsInt64(),
            "dateString": timestamp.ISOStringFromDate(),
            "type": "sgv",
            "sgv": glucoseFiltered,
            "direction": trend.toNightscout(),
            "noise": 1,
            "sysTime": timestamp.ISOStringFromDate()
        ]

        return nightscout
    }
}

fileprivate extension SensorTrend {
    func toNightscout() -> String {
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
