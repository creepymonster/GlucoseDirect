//
//  SensorReading.swift
//  LibreDirect
//

import Foundation

final class SensorReading: CustomStringConvertible, Codable {
    // MARK: Lifecycle
    
    init(id: UUID, timestamp: Date, quality: GlucoseQuality) {
        self.id = id
        self.timestamp = timestamp.rounded(on: 1, .minute)
        self.readGlucoseValue = nil
        self.quality = quality
    }

    init(id: UUID, timestamp: Date, glucoseValue: Double, quality: GlucoseQuality = .OK) {
        self.id = id
        self.timestamp = timestamp.rounded(on: 1, .minute)
        
        if quality == .OK {
            self.readGlucoseValue = glucoseValue
        } else {
            self.readGlucoseValue = nil
        }
        
        self.quality = quality
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let readGlucoseValue: Double?
    let quality: GlucoseQuality

    var glucoseValue: Double? {
        guard let readGlucoseValue = readGlucoseValue else {
            AppLog.info("Guard: readGlucoseValue is nil")
            return nil
        }
        
        let minReadableGlucose = Double(AppConfig.minReadableGlucose)
        let maxReadableGlucose = Double(AppConfig.maxReadableGlucose)

        if readGlucoseValue < minReadableGlucose {
            return minReadableGlucose
        } else if readGlucoseValue > maxReadableGlucose {
            return maxReadableGlucose
        }

        return readGlucoseValue
    }

    var description: String {
        [
            "id: \(id)",
            "timestamp: \(timestamp.localTime)",
            "glucoseValue: \(glucoseValue?.description ?? "-")",
            "quality: \(quality.description)"
        ].joined(separator: ", ")
    }
}

