//
//  Nightscout.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

func nightscoutMiddleware(service: NightscoutService) -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .setSensorReading(readingUpdate: let readingUpdate):
            let date = Date().rounded(on: 1, .minute)
            let minutes = Calendar.current.component(.minute, from: date)

            guard minutes % 5 == 0 else {
                break
            }
            
            let nightscoutHost = state.nightscoutHost
            let nightscoutApiSecret = state.nightscoutApiSecret

            guard !nightscoutHost.isEmpty else {
                break
            }

            guard !nightscoutApiSecret.isEmpty else {
                break
            }

            service.addGlucose(nightscoutHost: nightscoutHost, apiSecret: nightscoutApiSecret, glucoseValues: readingUpdate.glucoseTrend)

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
}

fileprivate extension SensorGlucose {
    func toNightscout() -> [String: Any] {
        let nightscout: [String: Any] = [
            "_id": id,
            "device": "LibreDirectPlayground",
            "date": timeStamp.toMillisecondsAsInt64(),
            "dateString": timeStamp.ISOStringFromDate(),
            "type": "sgv",
            "sgv": glucoseFiltered,
            "direction": trend.toNightscout(),
            "noise": 1,
            "sysTime": timeStamp.ISOStringFromDate()
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
