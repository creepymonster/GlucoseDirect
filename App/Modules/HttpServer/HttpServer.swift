//
//  HttpServer.swift
//  GlucoseDirectApp
//

import Combine
import Foundation
import MapKit
import Swifter

func httpServerMiddleware() -> Middleware<DirectState, DirectAction> {
    return httpServerMiddleware(service: HttpServerService())
}

private func httpServerMiddleware(service: HttpServerService) -> Middleware<DirectState, DirectAction> {
    return { state, action, lastState in
        switch action {
        case .startup:
            guard state.httpServer else {
                break
            }

            service.setGlucoseUnit(glucoseUnit: state.glucoseUnit)
            service.start()

        case .setHttpServer(enabled: let enabled):
            if enabled {
                service.setGlucoseValues(glucoseValues: state.sensorGlucoseValues)
                service.start()
            } else {
                service.setGlucoseValues(glucoseValues: [])
                service.stop()
            }

        case .setGlucoseUnit(unit: let unit):
            guard state.httpServer else {
                break
            }

            service.setGlucoseUnit(glucoseUnit: unit)

        case .setAppState(appState: let appState):
            guard appState == .active, lastState.appState == .background else {
                break
            }

            service.restart()

        case .setSensorGlucoseValues(glucoseValues: let glucoseValues):
            guard state.httpServer else {
                break
            }

            service.setGlucoseValues(glucoseValues: glucoseValues)

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - HttpServerService

private class HttpServerService {
    // MARK: Lifecycle

    init() {
        server = HttpServer()
        server["/sgv.json"] = { request in
            var count = self.glucoseValues.count
            if let countParamString = request.queryParams.filter({ $0.0 == "count" }).first?.1, let countParam = Int(countParamString) {
                count = countParam
            }

            let json = self.glucoseValues.prefix(count).map { value in
                value.toHttpServerGlucose(glucoseUnit: self.glucoseUnit)
            }

            return .ok(.json(json))
        }
    }

    // MARK: Internal

    func setGlucoseUnit(glucoseUnit: GlucoseUnit) {
        self.glucoseUnit = glucoseUnit
    }

    func setGlucoseValues(glucoseValues: [SensorGlucose]) {
        let nth = 5
        let limitedGlucoseValues = glucoseValues.suffix(200).reversed()

        self.glucoseValues = limitedGlucoseValues.enumerated().compactMap {
            if $0.offset % nth == nth - 1 || $0.element == limitedGlucoseValues.first {
                return $0.element
            }

            return nil
        }
    }

    func check(completionHandler: @escaping (Bool) -> Void) {
        let session = URLSession.shared
        let url = URL(string: "http://localhost:\(DirectConfig.httpServerPort)/sgv.json")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = session.dataTask(with: request) { _, response, error in
            if error == nil, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }

        task.resume()
    }

    func start() {
        DirectLog.info("start internal http server")

        // start background mode
        BackgroundManager.shared.enabled = true

        do {
            try server.start(DirectConfig.httpServerPort, forceIPv4: true)
        } catch {
            DirectLog.error("Server start error: \(error)")
        }
    }

    func stop() {
        DirectLog.info("stop internal http server")

        // stop background mode
        BackgroundManager.shared.enabled = false

        server.stop()
    }

    func restart() {
        DirectLog.info("restart internal http server")

        stop()
        start()
    }

    // MARK: Private

    private var glucoseUnit: GlucoseUnit = .mgdL
    private var glucoseValues: [SensorGlucose] = []
    private let server: HttpServer
}

private extension SensorGlucose {
    func toHttpServerGlucose(glucoseUnit: GlucoseUnit) -> [String: Any] {
        return [
            "_id": id.uuidString,
            "device": DirectConfig.projectName,
            "date": timestamp.toMillisecondsAsInt64(),
            "dateString": timestamp.toISOStringFromDate(),
            "type": "sgv",
            "sgv": glucoseValue,
            "direction": trend.toHttpServer(),
            "units_hint": glucoseUnit.toHttpServer()
        ]
    }
}

private extension GlucoseUnit {
    func toHttpServer() -> String {
        switch self {
        case .mgdL:
            return "mgdl"
        case .mmolL:
            return "mmoll"
        }
    }
}

private extension SensorTrend {
    func toHttpServer() -> String {
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

// MARK: - BackgroundManager

private class BackgroundManager: NSObject {
    // MARK: Lifecycle

    override init() {}

    // MARK: Internal

    static let shared = BackgroundManager()

    var isShowLog: Bool = true
    let systemVersion: Float = (UIDevice.current.systemVersion as NSString).floatValue

    var enabled: Bool = false {
        didSet {
            guard enabled != oldValue else {
                return
            }

            if enabled {
                guard isValidConfig else {
                    enabled = false
                    return
                }

                locationManager = makeLocationManager()

                addAppLifeCircleNotification()
            } else {
                locationManager?.stopUpdatingLocation()
                locationManager = nil

                removeAppLifeCircleNotification()
            }
        }
    }

    // MARK: Private

    private var locationManager: CLLocationManager?

    private var isValidConfig: Bool {
        if let info = Bundle.main.infoDictionary,
           info.keys.contains("NSLocationAlwaysAndWhenInUseUsageDescription"),
           info.keys.contains("NSLocationWhenInUseUsageDescription"),
           let bgModels = info["UIBackgroundModes"] as? [String],
           bgModels.contains("fetch"),
           bgModels.contains("location")
        {
            return true
        }

        return false
    }

    private var isAuthBackground: Bool {
        guard enabled else {
            return false
        }

        let status = locationManager?.authorizationStatus

        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
}

private extension BackgroundManager {
    func start() {
        guard isAuthBackground else {
            return
        }

        locationManager?.startUpdatingLocation()
    }

    func stop() {
        guard isAuthBackground else {
            return
        }

        locationManager?.stopUpdatingLocation()
    }

    func makeLocationManager() -> CLLocationManager {
        let manager = CLLocationManager()
        manager.distanceFilter = kCLDistanceFilterNone
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.pausesLocationUpdatesAutomatically = false
        manager.requestAlwaysAuthorization()
        manager.requestWhenInUseAuthorization()

        return manager
    }

    func addAppLifeCircleNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willTerminateNotification),
                                               name: UIApplication.willTerminateNotification,
                                               object: UIApplication.shared)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: UIApplication.shared)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForegroundNotification),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: UIApplication.shared)
    }

    func removeAppLifeCircleNotification() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: CLLocationManagerDelegate

extension BackgroundManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            manager.allowsBackgroundLocationUpdates = true
        default:
            break
        }
    }
}

// MARK: - App LifeCircle

extension BackgroundManager {
    @objc func willTerminateNotification() {
        guard isAuthBackground else {
            return
        }

        UIApplication.shared.beginReceivingRemoteControlEvents()
        start()
    }

    @objc func applicationDidEnterBackground() {
        guard isAuthBackground else {
            return
        }

        var bgTask: UIBackgroundTaskIdentifier?
        bgTask = UIApplication.shared.beginBackgroundTask {
            DispatchQueue.main.async {
                if let task = bgTask, task != .invalid {
                    bgTask = .invalid
                }
            }
        }

        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                if let task = bgTask, task != .invalid {
                    bgTask = .invalid
                }
            }
        }

        start()
    }

    @objc func willEnterForegroundNotification() {
        guard isAuthBackground else {
            return
        }

        stop()
    }
}
