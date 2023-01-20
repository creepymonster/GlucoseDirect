//
//  SensorWidget.swift
//  App
//

import SwiftUI
import WidgetKit

private let families: [WidgetFamily] = [.accessoryCircular]

// MARK: - SensorWidget

struct SensorWidget: Widget {
    let kind: String = "SensorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SensorUpdateProvider()) { entry in
            SensorWidgetView(entry: entry)
        }
        .supportedFamilies(families)
        .configurationDisplayName("Sensor lifetime widget")
        .description("Sensor lifetime widget description")
    }
}

// MARK: - SensorWidgetView

struct SensorWidgetView: View {
    @Environment(\.widgetFamily) var size

    var entry: SensorEntry

    var sensor: Sensor? {
        entry.sensor ?? UserDefaults.shared.sensor
    }

    var body: some View {
        switch size {
        case .accessoryCircular:
            if let sensor {
                Gauge(
                    value: Double(sensor.remainingWarmupTime == nil ? sensor.remainingLifetime : sensor.remainingWarmupTime!),
                    in: 0 ... Double(sensor.remainingWarmupTime == nil ? sensor.lifetime : sensor.warmupTime),
                    label: {
                        Text(sensor.remainingWarmupTime == nil ? sensor.family.localizedDescription : "Warmup")
                            .font(.system(size: 10))
                    }
                ).gaugeStyle(.accessoryCircularCapacity)
            } else {
                ZStack(alignment: .center) {
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 12, dash: [6, 3]))
                        .opacity(0.3)

                    Image(systemName: "questionmark")
                }
            }

        default:
            Text("")
        }
    }
}

// MARK: - SensorWidget_Previews

struct SensorWidget_Previews: PreviewProvider {
    static var previews: some View {
        SensorWidgetView(entry: SensorEntry(date: Date(), sensor: placeholderSensor))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))

        SensorWidgetView(entry: SensorEntry(date: Date(), sensor: placeholderStartingSensor))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
        
        SensorWidgetView(entry: SensorEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
