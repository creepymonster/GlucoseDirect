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
    return { state, action, lastState in
        let nightscoutURL = state.nightscoutURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let nightscoutApiSecret = state.nightscoutApiSecret

        if state.nightscoutUpload, !nightscoutURL.isEmpty, !nightscoutApiSecret.isEmpty {
            switch action {
            case .removeGlucose(id: let id):
                guard let glucose = lastState.glucoseValues.first(where: { $0.id == id }) else {
                    AppLog.info("Guard: lastState.glucoseValues.first with id \(id) not found")
                    break
                }

                service.removeGlucose(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1(), date: glucose.timestamp)

            case .clearGlucoseValues:
                service.clearGlucoseValues(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1())

            case .addGlucoseValues(glucoseValues: let glucoseValues):
                if glucoseValues.count > 1 {
                    let filteredGlucoseValues = glucoseValues.filter { glucose in
                        glucose.type != .none
                    }

                    service.addGlucose(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1(), glucoseValues: filteredGlucoseValues)
                } else if let glucose = glucoseValues.first, (glucose.type == .cgm && glucose.is5Minutely || state.sensorInterval > 1) || glucose.type == .bgm {
                    service.addGlucose(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1(), glucoseValues: [glucose])
                }

            case .setSensorState(sensorAge: _, sensorState: _):
                guard let sensor = state.sensor, sensor.startTimestamp != nil else {
                    AppLog.info("Guard: state.sensor or sensor.startTimestamp is nil")
                    break
                }

                guard lastState.sensor == nil || lastState.sensor!.startTimestamp == nil else {
                    AppLog.info("Guard: lastState.sensor and lastState.sensor!.startTimestamp not nil")
                    break
                }

                guard let serial = sensor.serial else {
                    AppLog.info("Guard: sensor.serial is nil")
                    break
                }

                service.isSensorStarted(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1(), serial: serial) { isStarted in
                    if let isStarted = isStarted, !isStarted {
                        service.setSensorStart(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1(), sensor: sensor)
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

    func setSensorStart(nightscoutURL: String, apiSecret: String, sensor: Sensor) {
        let nightscoutValue = sensor.toNightscoutSensorStart()

        guard let nightscoutValue = nightscoutValue else {
            return
        }

        guard let nightscoutJson = try? JSONSerialization.data(withJSONObject: nightscoutValue) else {
            return
        }

        let session = URLSession.shared

        let urlString = "\(nightscoutURL)/api/v1/treatments"
        guard let url = URL(string: urlString) else {
            AppLog.error("Nightscout, bad nightscout url")
            return
        }

        let request = createRequest(url: url, method: "POST", apiSecret: apiSecret)

        let task = session.uploadTask(with: request, from: nightscoutJson) { data, response, error in
            if let error = error {
                AppLog.info("Nightscout error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                let status = response.statusCode

                if status != 200, let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    AppLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

    func clearGlucoseValues(nightscoutURL: String, apiSecret: String) {
        let session = URLSession.shared

        let urlString = "\(nightscoutURL)/api/v1/entries?find[device]=\(AppConfig.projectName)"
        guard let url = URL(string: urlString) else {
            AppLog.error("Nightscout, bad nightscout url")
            return
        }

        let request = createRequest(url: url, method: "DELETE", apiSecret: apiSecret)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                AppLog.info("Nightscout error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                let status = response.statusCode
                if status != 200, let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    AppLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

    func removeGlucose(nightscoutURL: String, apiSecret: String, date: Date) {
        let session = URLSession.shared

        let urlString = "\(nightscoutURL)/api/v1/entries?find[device]=\(AppConfig.projectName)&find[dateString]=\(date.toISOStringFromDate())"
        guard let url = URL(string: urlString) else {
            AppLog.error("Nightscout, bad nightscout url")
            return
        }

        let request = createRequest(url: url, method: "DELETE", apiSecret: apiSecret)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                AppLog.info("Nightscout error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                let status = response.statusCode
                if status != 200, let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    AppLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

    func addGlucose(nightscoutURL: String, apiSecret: String, glucoseValues: [Glucose]) {
        let nightscoutValues = glucoseValues.map { $0.toNightscoutGlucose() }

        guard let nightscoutJson = try? JSONSerialization.data(withJSONObject: nightscoutValues) else {
            return
        }

        let session = URLSession.shared

        let urlString = "\(nightscoutURL)/api/v1/entries"
        guard let url = URL(string: urlString) else {
            AppLog.error("Nightscout, bad nightscout url")
            return
        }

        let request = createRequest(url: url, method: "POST", apiSecret: apiSecret)

        let task = session.uploadTask(with: request, from: nightscoutJson) { data, response, error in
            if let error = error {
                AppLog.info("Nightscout error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200, let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    AppLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

    func isSensorStarted(nightscoutURL: String, apiSecret: String, serial: String, completionHandler: @escaping (Bool?) -> Void) {
        let session = URLSession.shared

        let urlString = "\(nightscoutURL)/api/v1/treatments?find[_id][$in][]=\(serial)&find[eventType][$in][]=Sensor%20Start"
        guard let url = URL(string: urlString) else {
            AppLog.error("Nightscout, bad nightscout url")

            completionHandler(nil)
            return
        }

        let request = createRequest(url: url, method: "GET", apiSecret: apiSecret)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                AppLog.info("Nightscout error: \(error.localizedDescription)")

                completionHandler(nil)
                return
            }

            if let response = response as? HTTPURLResponse, let data = data {
                let status = response.statusCode
                if status != 200 {
                    let responseString = String(data: data, encoding: .utf8)

                    AppLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                    completionHandler(nil)
                } else {
                    do {
                        let results = try JSONDecoder().decode([Treatment].self, from: data)
                        completionHandler(!results.isEmpty)
                    } catch {
                        AppLog.info("Nightscout, json decode failed: \(error.localizedDescription)")
                        completionHandler(nil)
                    }
                }
            } else {
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
            "created_at": startTimestamp.toISOStringFromDate(),
            "enteredBy": AppConfig.projectName
        ]

        return nightscout
    }
}

private extension Glucose {
    func toNightscoutGlucose() -> [String: Any] {
        var nightscout: [String: Any] = [
            "_id": id.uuidString,
            "device": AppConfig.projectName,
            "date": timestamp.toMillisecondsAsInt64(),
            "dateString": timestamp.toISOStringFromDate()
        ]

        if type == .bgm {
            nightscout["type"] = "mbg"
            nightscout["mbg"] = glucoseValue
        } else if type == .cgm {
            nightscout["type"] = "sgv"
            nightscout["sgv"] = glucoseValue
            nightscout["rawbg"] = initialGlucoseValue
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
