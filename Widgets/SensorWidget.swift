//
//  SensorWidget.swift
//  App
//

import SwiftUI
import WidgetKit

private let placeholderSensor = Sensor(
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

private let placeholderStartingSensor = Sensor(
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
        let entry = SensorEntry()

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [
            SensorEntry()
        ]

        let reloadDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}

// MARK: - SensorView

struct SensorView: View {
    @Environment(\.widgetFamily) var size

    var entry: SensorEntry

    var sensor: Sensor? {
        entry.sensor ?? UserDefaults.shared.sensor
    }

    var body: some View {
        if let sensor {
            Gauge(
                value: Double(sensor.remainingWarmupTime == nil ? sensor.remainingLifetime : sensor.remainingWarmupTime!),
                in: 0 ... Double(sensor.remainingWarmupTime == nil ? sensor.lifetime : sensor.warmupTime),
                label: {
                    Text(sensor.remainingWarmupTime == nil ? sensor.family.localizedDescription : "Warmup")
                        .font(.system(size: 10))
                }
            )
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetBackground(backgroundView: Color("WidgetBackground"))
        } else {
            ZStack(alignment: .center) {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 12, dash: [6, 3]))
                    .opacity(0.3)

                Image(systemName: "questionmark")
            }
            .widgetBackground(backgroundView: Color("WidgetBackground"))
        }
    }
}

// MARK: - SensorWidget

struct SensorWidget: Widget {
    let kind: String = "SensorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SensorUpdateProvider()) { entry in
            SensorView(entry: entry)
        }
        .supportedFamilies([.accessoryCircular])
        .configurationDisplayName("Sensor lifetime widget")
        .description("Sensor lifetime widget description")
    }
}

// MARK: - SensorWidget_Previews

struct SensorWidget_Previews: PreviewProvider {
    static var previews: some View {
        SensorView(entry: SensorEntry(date: Date(), sensor: placeholderSensor))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))

        SensorView(entry: SensorEntry(date: Date(), sensor: placeholderStartingSensor))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
