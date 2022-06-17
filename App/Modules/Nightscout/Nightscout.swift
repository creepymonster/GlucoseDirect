//
//  Nightscout.swift
//  GlucoseDirect
//

import Combine
import Foundation

func nightscoutMiddleware() -> Middleware<AppState, AppAction> {
    return nightscoutMiddleware(service: LazyService<NightscoutService>(initialization: {
        NightscoutService()
    }))
}

private func nightscoutMiddleware(service: LazyService<NightscoutService>) -> Middleware<AppState, AppAction> {
    return { state, action, lastState in
        let nightscoutURL = state.nightscoutURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let nightscoutApiSecret = state.nightscoutApiSecret

        if state.nightscoutUpload, !nightscoutURL.isEmpty, !nightscoutApiSecret.isEmpty {
            switch action {
            case .removeGlucose(id: let id):
                guard let glucose = lastState.glucoseValues.first(where: { $0.id == id }) else {
                    DirectLog.info("Guard: lastState.glucoseValues.first with id \(id) not found")
                    break
                }

                service.value.removeGlucose(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1(), date: glucose.timestamp)

            case .clearGlucoseValues:
                service.value.clearGlucoseValues(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1())

            case .addGlucose(glucose: let glucose):
                guard glucose.type == .cgm || glucose.type == .bgm else {
                    break
                }

                service.value.addGlucose(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1(), glucose: glucose)

            case .setSensorState(sensorAge: _, sensorState: _):
                guard let sensor = state.sensor, sensor.startTimestamp != nil else {
                    DirectLog.info("Guard: state.sensor or sensor.startTimestamp is nil")
                    break
                }

                guard lastState.sensor == nil || lastState.sensor!.startTimestamp == nil else {
                    DirectLog.info("Guard: lastState.sensor and lastState.sensor!.startTimestamp not nil")
                    break
                }

                guard let serial = sensor.serial else {
                    DirectLog.info("Guard: sensor.serial is nil")
                    break
                }

                service.value.isSensorStarted(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1(), serial: serial) { isStarted in
                    if let isStarted = isStarted, !isStarted {
                        service.value.setSensorStart(nightscoutURL: nightscoutURL, apiSecret: nightscoutApiSecret.toSha1(), sensor: sensor)
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
    // MARK: Lifecycle

    init() {
        DirectLog.info("Create NightscoutService")
    }

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
            DirectLog.error("Nightscout, bad nightscout url")
            return
        }

        let request = createRequest(url: url, method: "POST", apiSecret: apiSecret)

        let task = session.uploadTask(with: request, from: nightscoutJson) { data, response, error in
            if let error = error {
                DirectLog.info("Nightscout error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                let status = response.statusCode

                if status != 200, let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    DirectLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

    func clearGlucoseValues(nightscoutURL: String, apiSecret: String) {
        let session = URLSession.shared

        let urlString = "\(nightscoutURL)/api/v1/entries?find[device]=\(DirectConfig.projectName)"
        guard let url = URL(string: urlString) else {
            DirectLog.error("Nightscout, bad nightscout url")
            return
        }

        let request = createRequest(url: url, method: "DELETE", apiSecret: apiSecret)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DirectLog.info("Nightscout error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                let status = response.statusCode
                if status != 200, let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    DirectLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

    func removeGlucose(nightscoutURL: String, apiSecret: String, date: Date) {
        let session = URLSession.shared

        let urlString = "\(nightscoutURL)/api/v1/entries?find[device]=\(DirectConfig.projectName)&find[dateString]=\(date.toISOStringFromDate())"
        guard let url = URL(string: urlString) else {
            DirectLog.error("Nightscout, bad nightscout url")
            return
        }

        let request = createRequest(url: url, method: "DELETE", apiSecret: apiSecret)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DirectLog.info("Nightscout error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                let status = response.statusCode
                if status != 200, let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    DirectLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

    func addGlucose(nightscoutURL: String, apiSecret: String, glucose: Glucose) {
        let nightscoutValues = glucose.toNightscoutGlucose()

        guard let nightscoutJson = try? JSONSerialization.data(withJSONObject: nightscoutValues) else {
            return
        }

        let session = URLSession.shared

        let urlString = "\(nightscoutURL)/api/v1/entries"
        guard let url = URL(string: urlString) else {
            DirectLog.error("Nightscout, bad nightscout url")
            return
        }

        let request = createRequest(url: url, method: "POST", apiSecret: apiSecret)

        let task = session.uploadTask(with: request, from: nightscoutJson) { data, response, error in
            if let error = error {
                DirectLog.info("Nightscout error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200, let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    DirectLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                }
            }
        }

        task.resume()
    }

    func isSensorStarted(nightscoutURL: String, apiSecret: String, serial: String, completionHandler: @escaping (Bool?) -> Void) {
        let session = URLSession.shared

        let urlString = "\(nightscoutURL)/api/v1/treatments?find[_id][$in][]=\(serial)&find[eventType][$in][]=Sensor%20Start"
        guard let url = URL(string: urlString) else {
            DirectLog.error("Nightscout, bad nightscout url")

            completionHandler(nil)
            return
        }

        let request = createRequest(url: url, method: "GET", apiSecret: apiSecret)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DirectLog.info("Nightscout error: \(error.localizedDescription)")

                completionHandler(nil)
                return
            }

            if let response = response as? HTTPURLResponse, let data = data {
                let status = response.statusCode
                if status != 200 {
                    let responseString = String(data: data, encoding: .utf8)

                    DirectLog.info("Nightscout error: \(response.statusCode) \(responseString)")
                    completionHandler(nil)
                } else {
                    do {
                        let results = try JSONDecoder().decode([Treatment].self, from: data)
                        completionHandler(!results.isEmpty)
                    } catch {
                        DirectLog.info("Nightscout, json decode failed: \(error.localizedDescription)")
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
            "enteredBy": DirectConfig.projectName
        ]

        return nightscout
    }
}

private extension Glucose {
    func toNightscoutGlucose() -> [String: Any] {
        var nightscout: [String: Any] = [
            "_id": id.uuidString,
            "device": DirectConfig.projectName,
            "date": timestamp.toMillisecondsAsInt64(),
            "dateString": timestamp.toISOStringFromDate()
        ]

        if type == .bgm {
            nightscout["type"] = "mbg"
            nightscout["mbg"] = glucoseValue
        } else if type == .cgm {
            nightscout["type"] = "sgv"
            nightscout["sgv"] = glucoseValue
            nightscout["rawbg"] = rawGlucoseValue
            nightscout["direction"] = trend.toNightscoutDirection()
            nightscout["trend"] = trend.toNightscoutTrend()
        }

        return nightscout
    }
}

// TEST
