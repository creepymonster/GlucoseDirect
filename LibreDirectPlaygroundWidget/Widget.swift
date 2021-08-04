//
//  Widget.swift
//  LibreDirectWidget
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
    
    var formatter: NumberFormatter {
        get {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            
            return formatter
        }
    }
    
    var minuteChange: String {
        get {
            if let glucose = entry.last, let minuteChange = glucose.minuteChange {
                if minuteChange > 0 {
                    return "+\(formatter.string(from: minuteChange as NSNumber)!)"
                } else if minuteChange < 0 {
                    return formatter.string(from: minuteChange as NSNumber)!
                } else {
                    return "0"
                }
            }
            
            return "0"
        }
    }
    
    var glucoseForegroundColor: Color {
        get {
            if let glucose = entry.last {
                Log.info("alarmLow: \(UserDefaults.appGroup.alarmLow)")
                if let alarmLow = UserDefaults.appGroup.alarmLow, glucose.glucoseFiltered < alarmLow {
                    return Color.red
                }
                
                Log.info("alarmHigh: \(UserDefaults.appGroup.alarmHigh)")
                if let alarmHigh = UserDefaults.appGroup.alarmHigh, glucose.glucoseFiltered > alarmHigh {
                    return Color.red
                }
            }

            return Color.primary
        }
    }

    var body: some View {
        if let glucose = entry.last {
            VStack {
                Text(glucose.glucoseFiltered.description).font(.system(size: 56)).foregroundColor(glucoseForegroundColor)
                               
                if let _ = glucose.minuteChange {
                    HStack {
                        Text(glucose.trend.description)
                        Text(String(format: LocalizedString("%1$@/min.", comment: ""), minuteChange))
                    }
                    .font(.footnote)
                    .padding(.bottom, 5)
                }
                
                Text(glucose.timeStamp.localTime)
            }
        } else {
            Text("...").font(.system(size: 56))
        }
    }
}

@main
struct LibreDirectPlaygroundWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.WidgetKind, provider: Provider()) { entry in
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
