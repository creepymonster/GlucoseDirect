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
    return { store, action, lastState in
        let nightscoutHost = store.state.nightscoutHost.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let nightscoutApiSecret = store.state.nightscoutApiSecret

        if store.state.nightscoutUpload, !nightscoutHost.isEmpty, !nightscoutApiSecret.isEmpty {
            switch action {
            case .removeGlucose(id: let id):
                service.removeGlucose(nightscoutHost: nightscoutHost, apiSecret: nightscoutApiSecret.toSha1(), id: id)

            case .addGlucose(glucose: let glucose):
                guard glucose.type != .none else {
                    break
                }

                guard glucose.is5Minutely || glucose.type == .bgm else {
                    break
                }

                service.addGlucose(nightscoutHost: nightscoutHost, apiSecret: nightscoutApiSecret.toSha1(), glucoseValues: [glucose])

            case .setSensorState(sensorAge: _, sensorState: _):
                guard let sensor = store.state.sensor, sensor.startTimestamp != nil else {
                    break
                }

                guard lastState.sensor == nil || lastState.sensor!.startTimestamp == nil else {
                    break
                }

                service.setSensorStart(nightscoutHost: nightscoutHost, apiSecret: nightscoutApiSecret.toSha1(), sensor: sensor)

            default:
                break
            }
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - NightscoutService

private class NightscoutService {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    func setSensorStart(nightscoutHost: String, apiSecret: String, sensor: Sensor) {
        let nightscoutValue = sensor.toNightscoutSensorStart()

        guard let nightscoutValue = nightscoutValue else {
            return
        }

        guard let nightscoutJson = try? JSONSerialization.data(withJSONObject: nightscoutValue) else {
            return
        }

        let session = URLSession.shared
        let url = URL(string: "\(nightscoutHost)/api/v1/treatments")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiSecret, forHTTPHeaderField: "api-secret")

        let task = session.uploadTask(with: request, from: nightscoutJson) { data, response, error in
            if let error = error {
                AppLog.info("Nightscout: \(error.localizedDescription)")
            }

            if let response = response as? HTTPURLResponse, let data = data {
                let status = response.statusCode
                if status != 200 {
                    let responseString = String(data: data, encoding: .utf8)
                    AppLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

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
                AppLog.info("Nightscout: \(error.localizedDescription)")
            }

            if let response = response as? HTTPURLResponse, let data = data {
                let status = response.statusCode
                if status != 200 {
                    let responseString = String(data: data, encoding: .utf8)
                    AppLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

    func addGlucose(nightscoutHost: String, apiSecret: String, glucoseValues: [Glucose]) {
        let nightscoutValues = glucoseValues.map { $0.toNightscoutGlucose() }

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
                AppLog.info("Nightscout: \(error.localizedDescription)")
            }

            if let response = response as? HTTPURLResponse, let data = data {
                let status = response.statusCode
                if status != 200 {
                    let responseString = String(data: data, encoding: .utf8)
                    AppLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }
}

private extension Sensor {
    func toNightscoutSensorStart() -> [String: Any]? {
        guard let startTimestamp = startTimestamp else {
            return nil
        }

        guard let serial = serial else {
            return nil
        }

        let nightscout: [String: Any] = [
            "_id": serial,
            "eventType": "Sensor Start",
            "created_at": startTimestamp.ISOStringFromDate(),
            "enteredBy": AppConfig.appName
        ]

        return nightscout
    }
}

private extension Glucose {
    func toNightscoutGlucose() -> [String: Any] {
        var nightscout: [String: Any] = [
            "_id": id.uuidString,
            "device": AppConfig.appName,
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
