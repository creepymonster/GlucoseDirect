//
//  GlucoseDirectWatchComplication.swift
//  GlucoseDirectWatchComplication
//

import WidgetKit
import SwiftUI


struct GlucoseComplicationView: View {
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
                        .font(.system(size: 20))
                        .bold()
                    
                    Text(glucose.timestamp.toLocalTime())
                        .font(.system(size: 10))
                }
                
            case .accessoryCorner:
                
                Text(glucose.trend.description)
                    .font(.system(size: 25))
                    .bold()
                    .widgetLabel {
                        Text("\(glucose.glucoseValue.asGlucose(glucoseUnit: glucoseUnit)) \(glucoseUnit.localizedDescription)")
                            .widgetAccentable()
                            .bold()
                        
                        
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


@main
struct GlucoseDirectWatchComplication: Widget {
    let kind: String = "GlucoseWatchComplication"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GlucoseUpdateProvider()) { entry in
            GlucoseComplicationView(entry: entry)
        }
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
        .configurationDisplayName("Glucose widget")
        .description("Glucose widget description")
    }
}


struct GlucoseDirectWatchComplication_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderLowGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Low Glucose, Rectangular, mgdL")
        
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderLowGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Low Glucose, Rectangular, mmo1L")
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Glucose, Rectangular, mgdL")
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Glucose, Rectangular, mmo1L")
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("High Glucose, Rectangular, mgdL")
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("High Glucose, Rectangular, mmo1L")
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("High Glucose, Circular, mgdL")
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("High Glucose, Circular, mmo1L")
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mgdL))
            .previewContext(WidgetPreviewContext(family: .accessoryCorner))
            .previewDisplayName("High Glucose, Corner, mgdL")
        
        GlucoseComplicationView(entry: GlucoseEntry(date: Date(), glucose: placeholderHighGlucose, glucoseUnit: .mmolL))
            .previewContext(WidgetPreviewContext(family: .accessoryCorner))
            .previewDisplayName("High Glucose, Corner, mmo1L")
        
    }
}
