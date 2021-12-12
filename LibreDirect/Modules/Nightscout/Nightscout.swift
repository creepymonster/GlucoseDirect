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

                guard let serial = sensor.serial else {
                    break
                }

                service.isSensorStarted(nightscoutHost: nightscoutHost, apiSecret: nightscoutApiSecret.toSha1(), serial: serial) { isStarted in
                    if let isStarted = isStarted, !isStarted {
                        service.setSensorStart(nightscoutHost: nightscoutHost, apiSecret: nightscoutApiSecret.toSha1(), sensor: sensor)
                    }
                }

            default:
                break
            }
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - NightscoutService

private class NightscoutService {
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

        let urlString = "\(nightscoutHost)/api/v1/treatments"
        AppLog.info("Nightscout request: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            AppLog.error("Bad url: \(urlString)")
            return
        }

        let request = createRequest(url: url, method: "POST", apiSecret: apiSecret)

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

        let urlString = "\(nightscoutHost)/api/v1/entries?find[_id][$in][]=\(id.uuidString)"
        AppLog.info("Nightscout request: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            AppLog.error("Bad url: \(urlString)")
            return
        }

        let request = createRequest(url: url, method: "DELETE", apiSecret: apiSecret)

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

        let urlString = "\(nightscoutHost)/api/v1/entries"
        AppLog.info("Nightscout request: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            AppLog.error("Bad url: \(urlString)")
            return
        }

        let request = createRequest(url: url, method: "POST", apiSecret: apiSecret)

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

    func isSensorStarted(nightscoutHost: String, apiSecret: String, serial: String, completionHandler: @escaping (Bool?) -> Void) {
        let session = URLSession.shared

        let urlString = "\(nightscoutHost)/api/v1/treatments?find[_id][$in][]=\(serial)&find[eventType][$in][]=Sensor%20Start"
        AppLog.info("Nightscout request: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            AppLog.error("Bad url: \(urlString)")

            completionHandler(nil)
            return
        }

        let request = createRequest(url: url, method: "GET", apiSecret: apiSecret)

        let task = session.dataTask(with: request) { data, _, error in
            if let error = error {
                AppLog.info("Nightscout: \(error.localizedDescription)")

                completionHandler(nil)
                return
            }

            guard let data = data else {
                AppLog.info("Nightscout, data is nil")

                completionHandler(nil)
                return
            }

            print(String(data: data, encoding: .utf8)!)

            do {
                let results = try JSONDecoder().decode([Treatment].self, from: data)
                completionHandler(results.count > 0)
            } catch {
                AppLog.info("Nightscout, json decode failed: \(error.localizedDescription)")
                completionHandler(nil)
            }
        }

        task.resume()
    }

    // MARK: Private

    private func createRequest(url: URL, method: String, apiSecret: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiSecret, forHTTPHeaderField: "api-secret")

        return request
    }
}

// MARK: - Treatment

private struct Treatment: Decodable {
    let _id: String
    let eventType: String
    let created_at: String
    let enteredBy: String
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
