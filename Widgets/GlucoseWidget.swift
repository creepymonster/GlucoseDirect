//
//  GlucoseWidget.swift
//  App
//

import SwiftUI
import WidgetKit

// MARK: - GlucoseView

struct GlucoseView: View {
    @Environment(\.widgetFamily) var size

    var entry: GlucoseEntry

    var glucoseUnit: GlucoseUnit? {
        entry.glucoseUnit ?? UserDefaults.shared.glucoseUnit
    }
    
    var glucose: SensorGlucose? {
        entry.glucose ?? UserDefaults.shared.latestSensorGlucose
    }

    var body: some View {
        if let glucose,
           let glucoseUnit
        {
            switch size {
            case .accessoryRectangular:
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .widgetAccentable()
                        .bold()
                        .font(.system(size: 35))

                    VStack(alignment: .leading) {
                        Text(glucose.trend.description)
                            .font(.system(size: 15))
                            .bold()

                        Text(glucose.timestamp.toLocalTime())
                            .font(.system(size: 10))
                    }
                }

            case .accessoryCircular:
                VStack(alignment: .center) {
                    Text(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .widgetAccentable()
                        .font(.system(size: 25))
                        .bold()

                    Text(glucose.timestamp.toLocalTime())
                        .font(.system(size: 10))
                }
                
            case .accessoryCorner:
                VStack(alignment: .center) {
                    Text(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .widgetAccentable()
                        .font(.system(size: 25))
                        .bold()

                    Text(glucose.timestamp.toLocalTime())
                        .font(.system(size: 10))
                }

            case .accessoryInline:
                VStack(alignment: .center) {
                    Text(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .widgetAccentable()
                        .font(.system(size: 25))
                        .bold()

                    Text(glucose.timestamp.toLocalTime())
                        .font(.system(size: 10))
                }

            default:
                Text("")
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
