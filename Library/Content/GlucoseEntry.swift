//
//  GlucoseEntry.swift
//  GlucoseDirect
//
//

import Foundation

// MARK: - GlucoseEntry

struct GlucoseEntry {
    // MARK: Lifecycle

    init() {
        self.date = Date()
        self.glucose = nil
        self.glucoseUnit = nil
    }

    init(date: Date) {
        self.date = date
        self.glucose = nil
        self.glucoseUnit = nil
    }

    init(date: Date, glucose: SensorGlucose, glucoseUnit: GlucoseUnit) {
        self.date = date
        self.glucose = glucose
        self.glucoseUnit = glucoseUnit
    }

    // MARK: Internal

    let date: Date
    let glucose: SensorGlucose?
    let glucoseUnit: GlucoseUnit?
}
