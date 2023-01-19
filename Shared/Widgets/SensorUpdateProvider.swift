//
//  SensorUpdateProvider.swift
//  GlucoseDirect
//

import Foundation
import WidgetKit

let placeholderSensor = Sensor(
    uuid: Data(hexString: "e9ad9b6c79bd93aa")!,
    patchInfo: Data(hexString: "448cd1")!,
    factoryCalibration: FactoryCalibration(i1: 1, i2: 2, i3: 4, i4: 8, i5: 16, i6: 32),
    family: .libre2,
    type: .virtual,
    region: .european,
    serial: "OBIR2PO",
    state: .ready,
    age: 3 * 24 * 60,
    lifetime: 14 * 24 * 60,
    warmupTime: 60
)

let placeholderStartingSensor = Sensor(
    uuid: Data(hexString: "e9ad9b6c79bd93aa")!,
    patchInfo: Data(hexString: "448cd1")!,
    factoryCalibration: FactoryCalibration(i1: 1, i2: 2, i3: 4, i4: 8, i5: 16, i6: 32),
    family: .libre2,
    type: .virtual,
    region: .european,
    serial: "OBIR2PO",
    state: .starting,
    age: 20,
    lifetime: 14 * 24 * 60,
    warmupTime: 60
)

// MARK: - SensorEntry

struct SensorEntry: TimelineEntry {
    // MARK: Lifecycle

    init() {
        self.date = Date()
        self.sensor = nil
    }

    init(date: Date) {
        self.date = date
        self.sensor = nil
    }

    init(date: Date, sensor: Sensor) {
        self.date = date
        self.sensor = sensor
    }

    // MARK: Internal

    let date: Date
    let sensor: Sensor?
}

// MARK: - SensorUpdateProvider

struct SensorUpdateProvider: TimelineProvider {
    func placeholder(in context: Context) -> SensorEntry {
        return SensorEntry(date: Date(), sensor: placeholderSensor)
    }

    func getSnapshot(in context: Context, completion: @escaping (SensorEntry) -> ()) {
        let entry = SensorEntry(date: Date(), sensor: placeholderSensor)

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SensorEntry>) -> ()) {
        let entries = [
            SensorEntry()
        ]

        let reloadDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}
