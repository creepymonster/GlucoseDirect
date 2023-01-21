//
//  TransmitterWidget.swift
//  WidgetsExtension
//

import SwiftUI
import WidgetKit

private let families: [WidgetFamily] = [.accessoryCircular]

// MARK: - TransmitterWidget

struct TransmitterWidget: Widget {
    let kind: String = "TransmitterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TransmitterUpdateProvider()) { entry in
            TransmitterWidgetView(entry: entry)
        }
        .supportedFamilies(families)
        .configurationDisplayName("Transmitter battery widget")
        .description("Transmitter battery widget description")
    }
}

// MARK: - TransmitterWidgetView

struct TransmitterWidgetView: View {
    @Environment(\.widgetFamily) var size

    var entry: TransmitterEntry

    var transmitter: Transmitter? {
        entry.transmitter ?? UserDefaults.shared.transmitter
    }

    var body: some View {
        switch size {
        case .accessoryCircular:
            if let transmitter {
                Gauge(
                    value: Double(transmitter.battery),
                    in: 0 ... 100,
                    label: {
                        Text(transmitter.name)
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

    func batteryImage(battery: Int) -> String {
        if battery < 1 {
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

// MARK: - TransmitterWidget_Previews

struct TransmitterWidget_Previews: PreviewProvider {   
    static var previews: some View {
        TransmitterWidgetView(entry: TransmitterEntry(date: Date(), transmitter: placeholderTransmitter))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
        
        TransmitterWidgetView(entry: TransmitterEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
