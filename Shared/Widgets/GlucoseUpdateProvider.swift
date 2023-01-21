//
//  GlucoseUpdateProvider.swift
//  GlucoseDirect
//

import Foundation
import WidgetKit

let placeholderLowGlucose = SensorGlucose(timestamp: Date(), rawGlucoseValue: 70, intGlucoseValue: 80, minuteChange: 2)
let placeholderGlucose = SensorGlucose(timestamp: Date(), rawGlucoseValue: 100, intGlucoseValue: 110, minuteChange: 5)
let placeholderHighGlucose = SensorGlucose(timestamp: Date(), rawGlucoseValue: 400, intGlucoseValue: 410, minuteChange: 5)
let placeholderGlucoseUnit = GlucoseUnit.mgdL

// MARK: - GlucoseEntry

struct GlucoseEntry: TimelineEntry {
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

// MARK: - GlucoseUpdateProvider

struct GlucoseUpdateProvider: TimelineProvider {
    func placeholder(in context: Context) -> GlucoseEntry {
        return GlucoseEntry(date: Date(), glucose: placeholderGlucose, glucoseUnit: placeholderGlucoseUnit)
    }

    func getSnapshot(in context: Context, completion: @escaping (GlucoseEntry) -> ()) {
        let entry = GlucoseEntry(date: Date(), glucose: placeholderGlucose, glucoseUnit: placeholderGlucoseUnit)

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GlucoseEntry>) -> ()) {
        let entries = [
            GlucoseEntry(),
        ]

        let reloadDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}
