//
//  FreeAPS.swift
//  LibreDirect
//

import Combine
import Foundation

func appGroupSharingMiddleware() -> Middleware<AppState, AppAction> {
    return appGroupSharingMiddleware(service: LazyService<AppGroupSharingService>(initialization: {
        AppGroupSharingService()
    }))
}

private func appGroupSharingMiddleware(service: LazyService<AppGroupSharingService>) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            service.value.clearAll()
            service.value.setApp(value: AppConfig.appName)
            service.value.setAppVersion(value: "\(AppConfig.appVersion) (\(AppConfig.appBuild))")

        case .selectConnection(id: _, connection: _):
            service.value.clearAll()

        case .setConnectionState(connectionState: let connectionState):
            if let sensor = state.sensor {
                service.value.setSensor(value: sensor.type.localizedString)
                service.value.setSensorState(value: sensor.state.localizedString)
                service.value.setSensorConnectionState(value: connectionState.localizedString)
            } else {
                service.value.setSensor(value: nil)
                service.value.setSensorState(value: nil)
                service.value.setSensorConnectionState(value: nil)
            }

        case .setSensor(sensor: let sensor, keepDevice: _):
            service.value.setSensor(value: sensor.type.localizedString)
            service.value.setSensorState(value: sensor.state.localizedString)
            service.value.setSensorConnectionState(value: state.connectionState.localizedString)

        case .setTransmitter(transmitter: let transmitter):
            service.value.setTransmitter(value: transmitter.name)
            service.value.setTransmitterBattery(value: "\(transmitter.battery)%")
            service.value.setTransmitterHardware(value: transmitter.hardware?.description)
            service.value.setTransmitterFirmware(value: transmitter.firmware?.description)

        case .disconnectConnection:
            service.value.clearGlucoseValues()

        case .pairConnection:
            service.value.clearGlucoseValues()

        case .addGlucoseValues(glucoseValues: let glucoseValues):
            guard let glucose = glucoseValues.last else {
                AppLog.info("Guard: glucoseValues.last is nil")
                break
            }
            
            if glucose.type == .cgm && glucose.isHIGH {
                break
            }

            service.value.setSensor(value: state.sensor?.type.localizedString)
            service.value.setSensorState(value: state.sensor?.state.localizedString)
            service.value.setSensorConnectionState(value: state.connectionState.localizedString)

            service.value.setTransmitter(value: state.transmitter?.name)

            if let transmitterBattery = state.transmitter?.battery {
                service.value.setTransmitterBattery(value: "\(transmitterBattery)%")
            } else {
                service.value.setTransmitterBattery(value: nil)
            }
            service.value.setTransmitterHardware(value: state.transmitter?.hardware?.description)
            service.value.setTransmitterFirmware(value: state.transmitter?.firmware?.description)

            service.value.addGlucose(glucoseValues: [glucose])

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - AppGroupSharingService

private class AppGroupSharingService {
    // MARK: Lifecycle

    init() {
        AppLog.info("Create AppGroupSharingService")
    }

    // MARK: Internal

    func clearGlucoseValues() {
        UserDefaults.shared.sharedGlucose = nil
    }

    func clearOthers() {
        UserDefaults.shared.sharedSensor = nil
        UserDefaults.shared.sharedSensorState = nil
        UserDefaults.shared.sharedSensorConnectionState = nil
        UserDefaults.shared.sharedTransmitter = nil
        UserDefaults.shared.sharedTransmitterBattery = nil
        UserDefaults.shared.sharedTransmitterHardware = nil
        UserDefaults.shared.sharedTransmitterFirmware = nil
    }

    func clearAll() {
        clearGlucoseValues()
        clearOthers()
    }

    func setApp(value: String?) {
        UserDefaults.shared.sharedApp = value
    }
    
    func setAppVersion(value: String?) {
        UserDefaults.shared.sharedAppVersion = value
    }

    func setSensor(value: String?) {
        UserDefaults.shared.sharedSensor = value
    }

    func setSensorState(value: String?) {
        UserDefaults.shared.sharedSensorState = value
    }

    func setSensorConnectionState(value: String?) {
        UserDefaults.shared.sharedSensorConnectionState = value
    }

    func setTransmitter(value: String?) {
        UserDefaults.shared.sharedTransmitter = value
    }

    func setTransmitterBattery(value: String?) {
        UserDefaults.shared.sharedTransmitterBattery = value
    }

    func setTransmitterHardware(value: String?) {
        UserDefaults.shared.sharedTransmitterHardware = value
    }

    func setTransmitterFirmware(value: String?) {
        UserDefaults.shared.sharedTransmitterFirmware = value
    }

    func addGlucose(glucoseValues: [Glucose]) {
        let sharedValues = glucoseValues
            .map { $0.toFreeAPS() }
            .compactMap { $0 }

        if sharedValues.isEmpty {
            return
        }

        AppLog.info("Shared values, values: \(sharedValues)")

        guard let sharedValuesJson = try? JSONSerialization.data(withJSONObject: sharedValues) else {
            return
        }

        AppLog.info("Shared values, json: \(sharedValuesJson)")

        UserDefaults.shared.sharedGlucose = sharedValuesJson
    }
}

private extension Glucose {
    func toFreeAPS() -> [String: Any]? {
        guard let glucoseValue = glucoseValue else {
            return nil
        }

        let date = "/Date(" + Int64(floor(timestamp.toMillisecondsAsDouble() / 1000) * 1000).description + ")/"

        let freeAPSGlucose: [String: Any] = [
            "Value": glucoseValue,
            "Trend": trend.toNightscoutTrend(),
            "DT": date,
            "direction": trend.toNightscoutDirection(),
            "from": AppConfig.projectName
        ]

        return freeAPSGlucose
    }
}
