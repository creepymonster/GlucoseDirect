//
//  DataStore.swift
//  GlucoseDirectApp
//
//  https://github.com/groue/GRDB.swift
//

import Combine
import Foundation
import GRDB

func dataStoreMigrationMiddleware() -> Middleware<DirectState, DirectAction> {
    return { _, action, _ in
        switch action {
        case .startup:
            if !UserDefaults.shared.gen1GlucoseValues.isEmpty { // migrate generation 1 values
                let sensorGlucoseValues = UserDefaults.shared.gen1GlucoseValues.map { value in
                    if let initialGlucoseValue = value.initialGlucoseValue, let calibratedGlucoseValue = value.calibratedGlucoseValue, value.type == .cgm {
                        return SensorGlucose(id: value.id, timestamp: value.timestamp, rawGlucoseValue: initialGlucoseValue, intGlucoseValue: calibratedGlucoseValue)
                    }

                    return nil
                }.compactMap {
                    $0
                }

                let bloodGlucoseValues = UserDefaults.shared.gen1GlucoseValues.map { value in
                    if let initialGlucoseValue = value.initialGlucoseValue, value.type == .bgm {
                        return BloodGlucose(id: value.id, timestamp: value.timestamp, glucoseValue: initialGlucoseValue)
                    }

                    return nil
                }.compactMap {
                    $0
                }

                UserDefaults.shared.gen1GlucoseValues = []

                return Publishers.MergeMany(
                    Just(DirectAction.addSensorGlucose(glucoseValues: sensorGlucoseValues)),
                    Just(DirectAction.addBloodGlucose(glucoseValues: bloodGlucoseValues))
                )
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()
            } else if !UserDefaults.shared.gen2GlucoseValues.isEmpty { // migrate generation 2 values
                let sensorGlucoseValues = UserDefaults.shared.gen2GlucoseValues.map { value in
                    if let rawGlucoseValue = value.rawGlucoseValue, let uncheckedGlucoseValue = value.uncheckedGlucoseValue, value.type == .cgm {
                        return SensorGlucose(id: value.id, timestamp: value.timestamp, rawGlucoseValue: rawGlucoseValue, intGlucoseValue: uncheckedGlucoseValue)
                    }

                    return nil
                }.compactMap {
                    $0
                }

                let bloodGlucoseValues = UserDefaults.shared.gen2GlucoseValues.map { value in
                    if let rawGlucoseValue = value.rawGlucoseValue, value.type == .bgm {
                        return BloodGlucose(id: value.id, timestamp: value.timestamp, glucoseValue: rawGlucoseValue)
                    }

                    return nil
                }.compactMap {
                    $0
                }

                UserDefaults.shared.gen2GlucoseValues = []

                return Publishers.MergeMany(
                    Just(DirectAction.addSensorGlucose(glucoseValues: sensorGlucoseValues)),
                    Just(DirectAction.addBloodGlucose(glucoseValues: bloodGlucoseValues))
                )
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - DataStore

class DataStore {
    // MARK: Lifecycle

    private init() {
        let filename = "GlucoseDirect.sqlite"
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = documentDirectory.appendingPathComponent(filename)

//        do {
//            try FileManager.default.removeItem(at: path)
//        } catch _ {
//        }

        do {
            dbQueue = try DatabaseQueue(path: path.absoluteString)
        } catch {
            DirectLog.error(error.localizedDescription)
            dbQueue = nil
        }
    }

    // MARK: Internal

    static let shared = DataStore()

    let dbQueue: DatabaseQueue?
}
