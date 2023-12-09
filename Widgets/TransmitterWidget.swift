//
//  TransmitterWidget.swift
//  WidgetsExtension
//

import SwiftUI
import WidgetKit

private let placeholderTransmitter = Transmitter(name: "Bubble", battery: 70, firmware: 2.0, hardware: 2.0)

// MARK: - TransmitterEntry

struct TransmitterEntry: TimelineEntry {
    // MARK: Lifecycle

    init() {
        self.date = Date()
        self.transmitter = nil
    }

    init(date: Date) {
        self.date = date
        self.transmitter = nil
    }

    init(date: Date, transmitter: Transmitter) {
        self.date = date
        self.transmitter = transmitter
    }

    // MARK: Internal

    let date: Date
    let transmitter: Transmitter?
}

// MARK: - TransmitterUpdateProvider

struct TransmitterUpdateProvider: TimelineProvider {
    func placeholder(in context: Context) -> TransmitterEntry {
        return TransmitterEntry(date: Date(), transmitter: placeholderTransmitter)
    }

    func getSnapshot(in context: Context, completion: @escaping (TransmitterEntry) -> ()) {
        let entry = TransmitterEntry()

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [
            TransmitterEntry()
        ]

        let reloadDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}

// MARK: - TransmitterView

struct TransmitterView: View {
    @Environment(\.widgetFamily) var size

    var entry: TransmitterEntry

    var transmitter: Transmitter? {
        entry.transmitter ?? UserDefaults.shared.transmitter
    }

    var body: some View {
        if let transmitter {
            Gauge(
                value: Double(transmitter.battery),
                in: 0 ... 100,
                label: {
                    Text(transmitter.name)
                        .font(.system(size: 10))
                }
            ).gaugeStyle(.accessoryCircularCapacity)
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

    func batteryImage(battery: Int) -> String {
        if battery == 0 {
            return "battery.0"
        } else if battery <= 25 {
            return "battery.25"
        } else if battery <= 50 {
            return "battery.50"
        } else if battery <= 75 {
            return "battery.75"
        }

        return "battery.100"
    }
}

// MARK: - TransmitterWidget

struct TransmitterWidget: Widget {
    let kind: String = "TransmitterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TransmitterUpdateProvider()) { entry in
            TransmitterView(entry: entry)
        }
        .supportedFamilies([.accessoryCircular])
        .configurationDisplayName("Transmitter battery widget")
        .description("Transmitter battery widget description")
    }
}

// MARK: - TransmitterWidget_Previews

struct TransmitterWidget_Previews: PreviewProvider {
    static var previews: some View {
        TransmitterView(entry: TransmitterEntry(date: Date(), transmitter: placeholderTransmitter))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
