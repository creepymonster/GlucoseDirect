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

            case .systemSmall:
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [.white, .ui.gray]), startPoint: .top, endPoint: .bottom)

                    VStack(spacing: 10) {
                        if let appIcon = UIImage(named: "AppIcon") {
                            Image(uiImage: appIcon)
                                .cornerRadius(4)
                        }

                        HStack(alignment: .lastTextBaseline, spacing: 10) {
                            if glucose.type != .high {
                                Text(verbatim: glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                                    .font(.system(size: 42))

                                VStack(alignment: .leading) {
                                    Text(verbatim: glucose.trend.description)
                                        .font(.system(size: 18))

                                    if let minuteChange = glucose.minuteChange?.asShortMinuteChange(glucoseUnit: glucoseUnit) {
                                        Text(verbatim: minuteChange)
                                            .font(.footnote)
                                    } else {
                                        Text(verbatim: "?")
                                            .font(.footnote)
                                    }
                                }
                            } else {
                                Text("HIGH")
                                    .font(.system(size: 64))
                                    .foregroundColor(Color.ui.red)
                            }
                        }

                        VStack {
                            Text("Updated")
                                .textCase(.uppercase)
                                .font(.footnote)
                            Text(glucose.timestamp, style: .time)
                                .monospacedDigit()
                        }
                        .opacity(0.5)
                        .font(.footnote)
                    }
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
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .systemSmall])
        .configurationDisplayName("Glucose widget")
        .description("Glucose widget description")
    }
}

// MARK: - GlucoseWidget_Previews

struct GlucoseWidget_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseView(entry: GlucoseEntry(date: Date(), glucose: placeholderLowGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

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
