//
//  LibreDirectPlaygroundWidget.swift
//  LibreDirectPlaygroundWidget
//
//  Created by Reimar Metzen on 28.07.21.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: TimelineProvider {
    let snapshotEntry = GlucoseEntry(date: Date(), last: SensorGlucose(timeStamp: Date(), glucose: 125))
    
    func placeholder(in context: Context) -> GlucoseEntry {
        snapshotEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (GlucoseEntry) -> Void) {
        let entry = snapshotEntry
        
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let lastGlucose = UserDefaults.appGroup.lastGlucose
        
        if let lastGlucose = lastGlucose {
            Log.info("lastGlucose: \(lastGlucose)")
        }
        
        let entries = [GlucoseEntry(date: Date(), last: lastGlucose)]
        
        //let roundedDate = Date().rounded(on: 5, .minute)
        //let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: roundedDate)!
        //Log.info("roundedDate: \(roundedDate.localTime)")
        //Log.info("refreshDate: \(refreshDate.localTime)")
        
        let timeline = Timeline(entries: entries, policy: .never)
        
        completion(timeline)
    }
}

struct GlucoseEntry: TimelineEntry {
    let date: Date
    let last: SensorGlucose?
}

struct LibreDirectPlaygroundWidgetEntryView: View {
    var entry: Provider.Entry
    
    var minuteChange: String {
        get {
            if let lastGlucose = entry.last {
                if lastGlucose.minuteChange > 0 {
                    return "+\(lastGlucose.minuteChange)"
                } else if lastGlucose.minuteChange < 0 {
                    return "-\(lastGlucose.minuteChange)"
                } else {
                    return "0"
                }
            }
            
            return ""
        }
    }
    
    var glucoseForegroundColor: Color {
        get {
            if let lastGlucose = entry.last {
                Log.info("alarmLow: \(UserDefaults.appGroup.alarmLow)")
                if let alarmLow = UserDefaults.appGroup.alarmLow, lastGlucose.glucoseFiltered < alarmLow {
                    return Color.red
                }
                
                Log.info("alarmHigh: \(UserDefaults.appGroup.alarmHigh)")
                if let alarmHigh = UserDefaults.appGroup.alarmHigh, lastGlucose.glucoseFiltered > alarmHigh {
                    return Color.red
                }
            }

            return Color.primary
        }
    }

    var body: some View {
        if let lastGlucose = entry.last {
            VStack {
                Text(lastGlucose.glucoseFiltered.description).font(.system(size: 56)).foregroundColor(glucoseForegroundColor)
                
                HStack {
                    Text(lastGlucose.trend.description)
                    Text("\(minuteChange)/min.")
                }.font(.footnote).padding(.bottom, 5)
                
                Text(lastGlucose.timeStamp.localTime)
            }
        } else {
            Text("...").font(.system(size: 56))
        }
    }
}

@main
struct LibreDirectPlaygroundWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Constants.WidgetKind, provider: Provider()) { entry in
            LibreDirectPlaygroundWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Glucoe Widget")
        .description("Shows the last glucose value")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct LibreDirectPlaygroundWidget_Previews: PreviewProvider {
    static var previews: some View {
        let date = Date()

        LibreDirectPlaygroundWidgetEntryView(entry: GlucoseEntry(date: date, last: SensorGlucose(id: 1, timeStamp: Date(), glucose: 125, minuteChange: +2))).previewContext(WidgetPreviewContext(family: .systemSmall))
        LibreDirectPlaygroundWidgetEntryView(entry: GlucoseEntry(date: date, last: nil)).previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
