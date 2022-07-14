//
//  Glucose.swift
//  GlucoseDirect
//

import Foundation

// MARK: - Glucose

protocol Glucose: Equatable {
    var id: UUID { get }
    var timestamp: Date { get }
    var glucoseValue: Int { get }
}

extension Glucose {
    func isMinutly(ofMinutes: Int) -> Bool {
        let minutes = Calendar.current.component(.minute, from: timestamp)

        return minutes % ofMinutes == 0
    }

    static func == (lhs: any Glucose, rhs: any Glucose) -> Bool {
        lhs.id == rhs.id
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
