//
//  GlucoseWidget.swift
//  App
//

import SwiftUI
import WidgetKit

private let families: [WidgetFamily] = [.accessoryRectangular, .accessoryCircular, .systemSmall]

// MARK: - GlucoseWidget

struct GlucoseWidget: Widget {
    let kind: String = "GlucoseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GlucoseUpdateProvider()) { entry in
            GlucoseWidgetView(entry: entry)
        }
        .supportedFamilies(families)
        .configurationDisplayName("Glucose widget")
        .description("Glucose widget description")
    }
}

// MARK: - GlucoseWidgetView

struct GlucoseWidgetView: View {
    @Environment(\.widgetFamily) var size

    var entry: GlucoseEntry

    var glucoseUnit: GlucoseUnit {
        entry.glucoseUnit ?? UserDefaults.shared.glucoseUnit
    }

    var glucose: SensorGlucose? {
        entry.glucose ?? UserDefaults.shared.latestSensorGlucose
    }

    var body: some View {
        if let glucose {
            switch size {
            case .accessoryRectangular:
                VStack {
                    HStack(alignment: .top) {
                        Text(verbatim: glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                            .bold()
                            .font(.system(size: 32))
                            .foregroundColor(DirectHelper.getGlucoseColor(glucose: glucose))

                        Text(verbatim: glucose.trend.description)
                            .font(.system(size: 20))
                    }
                    
                    HStack {
                        Text(glucose.timestamp, style: .time)
                            .bold()
                            .monospacedDigit()

                        if let minuteChange = glucose.minuteChange?.asMinuteChange(glucoseUnit: glucoseUnit) {
                            Text(verbatim: minuteChange)
                        } else {
                            Text(verbatim: "?")
                        }
                    }.font(.system(size: 12))
                }

            case .accessoryCircular:
                VStack(alignment: .center) {
                    Text(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .bold()
                        .font(.system(size: 16))

                    Text(glucose.timestamp.toLocalTime())
                        .font(.system(size: 12))
                }

            case .systemSmall:
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [.white, .ui.gray]), startPoint: .top, endPoint: .bottom)

                    VStack(spacing: 10) {
                        HStack(alignment: .lastTextBaseline, spacing: 10) {
                            Text(verbatim: glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                                .bold()
                                .font(.system(size: 40))
                                .foregroundColor(DirectHelper.getGlucoseColor(glucose: glucose))

                            VStack(alignment: .leading) {
                                Text(verbatim: glucose.trend.description)
                                    .font(.system(size: 16))

                                Group {
                                    if let minuteChange = glucose.minuteChange?.asShortMinuteChange(glucoseUnit: glucoseUnit) {
                                        Text(verbatim: minuteChange)
                                    } else {
                                        Text(verbatim: "?")
                                    }
                                }.font(.system(size: 12))
                            }
                        }

                        VStack {
                            Text("Updated")
                                .textCase(.uppercase)
                            Text(glucose.timestamp, style: .time)
                                .monospacedDigit()
                        }
                        .font(.system(size: 12))
                        .opacity(0.5)
                    }
                }

            default:
                Text("")
            }
        }
    }
}

// MARK: - GlucoseWidget_Previews

struct GlucoseWidget_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseWidgetView(entry: GlucoseEntry(date: Date(), glucose: placeholderLowGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

        GlucoseWidgetView(entry: GlucoseEntry(date: Date(), glucose: placeholderGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

        GlucoseWidgetView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
