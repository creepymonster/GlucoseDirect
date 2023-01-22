//
//  Complication.swift
//  GlucoseDirect
//

import SwiftUI
import WidgetKit

private let families: [WidgetFamily] = [.accessoryRectangular, .accessoryCircular, .accessoryCorner, .accessoryInline]

// MARK: - GlucoseDirectComplications

@main
struct GlucoseDirectComplications: WidgetBundle {
    var body: some Widget {
        GlucoseComplication()
    }
}

// MARK: - GlucoseComplication

struct GlucoseComplication: Widget {
    let kind: String = "GlucoseComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GlucoseUpdateProvider()) { entry in
            GlucoseComplicationView(entry: entry)
        }
        .supportedFamilies(families)
        .configurationDisplayName("Glucose widget")
        .description("Glucose widget description")
    }
}

// MARK: - GlucoseComplicationView

struct GlucoseComplicationView: View {
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
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .bold()
                        .font(.system(size: 40))
                        .foregroundColor(DirectHelper.getGlucoseColor(glucose: glucose))
                    
                    VStack(alignment: .leading) {
                        Text(glucose.trend.description)
                            .font(.system(size: 16))
                        
                        Text(glucose.timestamp.toLocalTime())
                            .font(.system(size: 12))
                    }
                }
                
            case .accessoryCircular:
                VStack(alignment: .center, spacing: 0) {
                    Text(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit))
                        .bold()
                        .font(.system(size: 16))
                        .foregroundColor(DirectHelper.getGlucoseColor(glucose: glucose))
                    
                    Text(glucose.timestamp.toLocalTime())
                        .font(.system(size: 8))
                }
                
            case .accessoryCorner:
                Text(glucose.trend.description)
                    .font(.system(size: 25))
                    .widgetLabel {
                        Text("\(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit)) \(glucoseUnit.localizedDescription)")
                            .bold()
                            .foregroundColor(DirectHelper.getGlucoseColor(glucose: glucose))
                    }
                
            case .accessoryInline:
                Text(verbatim: "\(glucose.trend.description) \(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit)), \(glucose.timestamp.toLocalTime())")
                
            default:
                Text("")
            }
        }
    }
}

// MARK: - GlucoseDirectWatchComplication_Previews

struct GlucoseDirectWatchComplication_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderLowGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderLowGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
    }
}
