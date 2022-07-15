//
//  Migration.swift
//  GlucoseDirectApp
//

import Combine
import Foundation

func dataStoreMigrationMiddleware() -> Middleware<DirectState, DirectAction> {
    return { _, action, _ in
        switch action {
        case .startup:
            let gen1Data = UserDefaults.shared.gen1GlucoseValues + UserDefaults.standard.gen1GlucoseValues
            let gen2Data = UserDefaults.shared.gen2GlucoseValues + UserDefaults.standard.gen2GlucoseValues

            if !gen1Data.isEmpty { // migrate generation 1 values
                let sensorGlucoseValues = gen1Data.toSensorGlucose()
                let bloodGlucoseValues = gen1Data.toBloodGlucose()

                UserDefaults.shared.gen1GlucoseValues = []
                UserDefaults.standard.gen1GlucoseValues = []

                return Publishers.MergeMany(
                    Just(DirectAction.addSensorGlucose(glucoseValues: sensorGlucoseValues)),
                    Just(DirectAction.addBloodGlucose(glucoseValues: bloodGlucoseValues))
                )
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()
            } else if !gen2Data.isEmpty { // migrate generation 2 values
                let sensorGlucoseValues = gen2Data.toSensorGlucose()
                let bloodGlucoseValues = gen2Data.toBloodGlucose()

                UserDefaults.shared.gen2GlucoseValues = []
                UserDefaults.standard.gen2GlucoseValues = []

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

extension UserDefaults {
    var gen1GlucoseValues: [Gen1Glucose] {
        get {
            return getArray(forKey: "libre-direct.settings.glucose-value-array") ?? []
        }
        set {
            setArray(newValue, forKey: "libre-direct.settings.glucose-value-array")
        }
    }

    var gen2GlucoseValues: [Gen2Glucose] {
        get {
            return getArray(forKey: "libre-direct.settings.glucose-values") ?? []
        }
        set {
            setArray(newValue, forKey: "libre-direct.settings.glucose-values")
        }
    }
}

// MARK: - Gen1Glucose

@available(*, deprecated)
class Gen1Glucose: CustomStringConvertible, Codable {
    let id: UUID
    let timestamp: Date
    let minuteChange: Double?
    let initialGlucoseValue: Int?
    let calibratedGlucoseValue: Int?
    let type: Gen1GlucoseType
    let quality: SensorReadingError

    var description: String {
        "{ id: \(id), timestamp: \(timestamp.toLocalTime()), minuteChange: \(minuteChange?.description ?? ""), initialGlucoseValue: \(initialGlucoseValue?.description ?? "-"), calibratedGlucoseValue: \(calibratedGlucoseValue?.description ?? "-"), type: \(type) }"
    }
}

// MARK: - Gen1GlucoseType

@available(*, deprecated)
enum Gen1GlucoseType: String, Codable {
    case cgm = "CGM"
    case bgm = "BGM"
    case none = "None"
}

extension Array where Element == Gen1Glucose {
    func toSensorGlucose() -> [SensorGlucose] {
        return map { value in
            if let initialGlucoseValue = value.initialGlucoseValue, let calibratedGlucoseValue = value.calibratedGlucoseValue, value.type == .cgm {
                return SensorGlucose(id: value.id, timestamp: value.timestamp, rawGlucoseValue: initialGlucoseValue, intGlucoseValue: calibratedGlucoseValue)
            }

            return nil
        }.compactMap {
            $0
        }
    }

    func toBloodGlucose() -> [BloodGlucose] {
        return map { value in
            if let initialGlucoseValue = value.initialGlucoseValue, value.type == .bgm {
                return BloodGlucose(id: value.id, timestamp: value.timestamp, glucoseValue: initialGlucoseValue)
            }

            return nil
        }.compactMap {
            $0
        }
    }
}

// MARK: - Gen2Glucose

@available(*, deprecated)
class Gen2Glucose: CustomStringConvertible, Codable {
    let id: UUID
    let timestamp: Date
    let minuteChange: Double?
    let rawGlucoseValue: Int?
    let type: Gen2GlucoseType
    let uncheckedGlucoseValue: Int?

    var description: String {
        "{ id: \(id), timestamp: \(timestamp.toLocalTime()), minuteChange: \(minuteChange?.description ?? ""), rawGlucoseValue: \(rawGlucoseValue?.description ?? "-"), uncheckedGlucoseValue: \(uncheckedGlucoseValue?.description ?? "-"), type: \(type) }"
    }
}

// MARK: - Gen2GlucoseType

@available(*, deprecated)
enum Gen2GlucoseType: Equatable, Codable {
    case cgm
    case bgm
    case faulty(SensorReadingError)

    // MARK: Internal

    var localizedString: String {
        switch self {
        case .cgm:
            return LocalizedString("CGM")
        case .bgm:
            return LocalizedString("BGM")
        case .faulty(quality: let quality):
            return LocalizedString("Failure: \(quality.description)")
        }
    }
}

extension Array where Element == Gen2Glucose {
    func toSensorGlucose() -> [SensorGlucose] {
        return map { value in
            if let rawGlucoseValue = value.rawGlucoseValue, let uncheckedGlucoseValue = value.uncheckedGlucoseValue, value.type == .cgm {
                return SensorGlucose(id: value.id, timestamp: value.timestamp, rawGlucoseValue: rawGlucoseValue, intGlucoseValue: uncheckedGlucoseValue)
            }

            return nil
        }.compactMap {
            $0
        }
    }

    func toBloodGlucose() -> [BloodGlucose] {
        return map { value in
            if let rawGlucoseValue = value.rawGlucoseValue, value.type == .bgm {
                return BloodGlucose(id: value.id, timestamp: value.timestamp, glucoseValue: rawGlucoseValue)
            }

            return nil
        }.compactMap {
            $0
        }
    }
}
