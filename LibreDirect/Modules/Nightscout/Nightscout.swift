//
//  Nightscout.swift
//  LibreDirect
//

import Combine
import Foundation

func nightscoutMiddleware() -> Middleware<AppState, AppAction> {
    return nightscoutMiddleware(service: NightscoutService())
}

private func nightscoutMiddleware(service: NightscoutService) -> Middleware<AppState, AppAction> {
    return { store, action, _ in
        switch action {
        case .removeGlucose(id: let id):
            let nightscoutHost = store.state.nightscoutHost
            let nightscoutApiSecret = store.state.nightscoutApiSecret

            guard !nightscoutHost.isEmpty else {
                break
            }

            guard !nightscoutApiSecret.isEmpty else {
                break
            }

            service.removeGlucose(nightscoutHost: nightscoutHost.trimmingCharacters(in: CharacterSet(charactersIn: "/")), apiSecret: nightscoutApiSecret.toSha1(), id: id)
        case .addGlucose(glucose: let glucose):
            guard store.state.nightscoutUpload else {
                break
            }
            
            guard glucose.type != .none else {
                break
            }

            guard glucose.is5Minutely || glucose.type == .bgm else {
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

// MARK: - NightscoutService

private class NightscoutService {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    func removeGlucose(nightscoutHost: String, apiSecret: String, id: UUID) {
        let session = URLSession.shared
        let url = URL(string: "\(nightscoutHost)/api/v1/entries?find[_id][$in][]=\(id.uuidString)")!

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiSecret, forHTTPHeaderField: "api-secret")

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                Log.info("Nightscout: \(error.localizedDescription)")
            }

            if let response = response as? HTTPURLResponse, let data = data {
                let status = response.statusCode
                if status != 200 {
                    let responseString = String(data: data, encoding: .utf8)
                    Log.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

    func addGlucose(nightscoutHost: String, apiSecret: String, glucoseValues: [Glucose]) {
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

            if let response = response as? HTTPURLResponse, let data = data {
                let status = response.statusCode
                if status != 200 {
                    let responseString = String(data: data, encoding: .utf8)
                    Log.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }
}

private extension Glucose {
    func toNightscout() -> [String: Any] {
        var nightscout: [String: Any] = [
            "_id": id.uuidString,
            "device": "LibreDirect",
            "date": timestamp.toMillisecondsAsInt64(),
            "dateString": timestamp.ISOStringFromDate()
        ]

        if type == .bgm {
            nightscout["type"] = "mbg"
            nightscout["mbg"] = glucoseValue
        } else if type == .cgm {
            nightscout["type"] = "sgv"
            nightscout["sgv"] = glucoseValue
            nightscout["direction"] = trend.toNightscout()
        }

        return nightscout
    }
}

private extension SensorTrend {
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
