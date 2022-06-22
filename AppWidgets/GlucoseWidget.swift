//
//  GlucoseWidget.swift
//  App
//

import SwiftUI
import WidgetKit

private let placeholderLowGlucose = Glucose.sensorGlucose(timestamp: Date(), rawGlucoseValue: 70, glucoseValue: 80, minuteChange: 2)
private let placeholderGlucose = Glucose.sensorGlucose(timestamp: Date(), rawGlucoseValue: 100, glucoseValue: 110, minuteChange: 5)
private let placeholderHighGlucose = Glucose.sensorGlucose(timestamp: Date(), rawGlucoseValue: 400, glucoseValue: 410, minuteChange: 5)
private let placeholderGlucoseUnit = GlucoseUnit.mgdL

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

    init(date: Date, glucose: Glucose, glucoseUnit: GlucoseUnit) {
        self.date = date
        self.glucose = glucose
        self.glucoseUnit = glucoseUnit
    }

    // MARK: Internal

    let date: Date
    let glucose: Glucose?
    let glucoseUnit: GlucoseUnit?
}

// MARK: - GlucoseUpdateProvider

struct GlucoseUpdateProvider: TimelineProvider {
    func placeholder(in context: Context) -> GlucoseEntry {
        return GlucoseEntry(date: Date(), glucose: placeholderGlucose, glucoseUnit: placeholderGlucoseUnit)
    }

    func getSnapshot(in context: Context, completion: @escaping (GlucoseEntry) -> ()) {
        let entry = GlucoseEntry()

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [
            GlucoseEntry(),
        ]

        let reloadDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}

// MARK: - GlucoseView

struct GlucoseView: View {
    @Environment(\.widgetFamily) var size

    var entry: GlucoseEntry

    var glucose: Glucose? {
        entry.glucose ?? UserDefaults.shared.latestGlucose
    }

    var glucoseUnit: GlucoseUnit? {
        entry.glucoseUnit ?? UserDefaults.shared.glucoseUnit
    }

    var body: some View {
        if let glucose,
           let glucoseUnit,
           let glucoseValue = glucose.glucoseValue
        {
            switch size {
            case .accessoryRectangular:
                HStack(alignment: .lastTextBaseline) {
                    Text(glucoseValue.asGlucose(unit: glucoseUnit))
                        .widgetAccentable()
                        .bold()
                        .font(.system(size: 35))

                    VStack(alignment: .leading) {
                        Text(glucose.trend.description)
                            .font(.system(size: 15))
                            .bold()

                        Text(String(format: LocalizedString("%1$@ a clock"), glucose.timestamp.toLocalTime()))
                            .font(.system(size: 10))
                    }
                }

            case .accessoryCircular:
                VStack(alignment: .center) {
                    Text(glucoseValue.asGlucose(unit: glucoseUnit))
                        .widgetAccentable()
                        .font(.system(size: 25))
                        .bold()

                    Text(String(format: LocalizedString("%1$@ a clock"), glucose.timestamp.toLocalTime()))
                        .font(.system(size: 10))
                }

            default:
                Text("Unknown size")
            }
        }
    }
}

// MARK: - GlucoseWidget

struct GlucoseWidget: Widget {
    let kind: String = "GlucoseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GlucoseUpdateProvider()) { entry in
            GlucoseView(entry: entry)
        }
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
        .configurationDisplayName("Glucose widget")
        .description("Glucose widget description")
    }
}

// MARK: - GlucoseWidget_Previews

struct GlucoseWidget_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseView(entry: GlucoseEntry(date: Date(), glucose: placeholderLowGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

        GlucoseView(entry: GlucoseEntry(date: Date(), glucose: placeholderLowGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        
        GlucoseView(entry: GlucoseEntry(date: Date(), glucose: placeholderGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

        GlucoseView(entry: GlucoseEntry(date: Date(), glucose: placeholderGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        
        GlucoseView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

        GlucoseView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

        GlucoseView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))

        GlucoseView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
