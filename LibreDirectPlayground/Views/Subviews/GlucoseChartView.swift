//
//  GlucoseChartView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 26.07.21.
//

import SwiftUI
import Combine

extension SensorGlucose: Equatable {
    static func == (lhs: SensorGlucose, rhs: SensorGlucose) -> Bool {
        lhs.timeStamp == rhs.timeStamp
    }
}

extension Date {
    static func dates(from fromDate: Date, to toDate: Date) -> [Date] {
        var dates: [Date] = []
        var date = fromDate
        
        while date <= toDate {
            dates.append(date)
            guard let newDate = Calendar.current.date(byAdding: .minute, value: 15, to: date) else {
                break
            }
            date = newDate
        }
        return dates
    }
}

struct GlucoseChartView: View {
    private enum Config {
        static let alarmGridColor = Color.red.opacity(0.5)
        static let alarmStrokeStyle = StrokeStyle(lineWidth: 0.2, dash: [5])
        static let darkDotColor = Color.accentColor
        static let dotSize: CGFloat = 4
        static let endID = "End"
        static let height: CGFloat = 350
        static let lightDotColor = Color.accentColor
        static let maxGlucose = 400
        static let minGlucose = 0
        static let targetGridColor = Color.green.opacity(0.5)
        static let targetStrokeStyle = StrokeStyle(lineWidth: 0.2, dash: [5])
        static let xGridColor = Color.secondary.opacity(0.25)
        static let xGridFontSize: CGFloat = 12
        static let xGridStrokeStyle = StrokeStyle(lineWidth: 0.2, dash: [1])
        static let xStep: CGFloat = Config.dotSize + Config.dotSize / 2
        static let yAdditionalBottom: CGFloat = Config.yGridFontSize * 2
        static let yGridColor = Color.secondary.opacity(0.25)
        static let yGridFontSize: CGFloat = 12
        static let yGridStrokeStyle = StrokeStyle(lineWidth: 0.2, dash: [1])
        static let yGridFontWidth: CGFloat = 28
        static let yGridPadding: CGFloat = 20
        static let yStep = 50
    }
    
    @Environment(\.colorScheme) var colorScheme

    var glucoseValues: [SensorGlucose]
    var glucoseUnit: GlucoseUnit
    var alarmLow: Int?
    var alarmHigh: Int?
    var targetValue: Int?
    
    var firstTimestamp: Date? {
        get {
            if let first = glucoseValues.first {
                return first.timeStamp.addingTimeInterval(-1 * 5 * 60)
            }
            
            return nil
        }
    }
    
    var lastTimeStamp: Date? {
        get {
            if let last = glucoseValues.last {
                return last.timeStamp.addingTimeInterval(5 * 60)
            }
            
            return nil
        }
    }

    var glucoseMinutes: Int {
        get {
            if let first = firstTimestamp, let last = lastTimeStamp {
                return Int(first.distance(to: last) / 60)
            }

            return 0
        }
    }

    var dotColor: Color {
        get {
            if colorScheme == .dark {
                return Config.darkDotColor
            }

            return Config.lightDotColor
        }
    }

    func minuteToX(minute: Int) -> CGFloat {
        return CGFloat(minute) * Config.xStep
    }

    func timestampToX(timeStamp: Date) -> CGFloat {
        if let first = firstTimestamp {
            let minute = Int(first.distance(to: timeStamp) / 60)
            
            return minuteToX(minute: minute)
        }

        return 0
    }

    func glucoseToY(fullSize: CGSize, glucose: CGFloat) -> CGFloat {
        let inMin = CGFloat(Config.minGlucose)
        let inMax = CGFloat(Config.maxGlucose)
        let outMin = fullSize.height - Config.yAdditionalBottom
        let outMax = CGFloat(0)

        let y = (glucose - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
        return y
    }

    var body: some View {
        if glucoseValues.count > 2 {
            GroupBox(label: Text(String(format: LocalizedString("Chart (%@)", comment: ""), glucoseValues.count.description)).padding(.bottom).foregroundColor(.accentColor)) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        yGridView(fullSize: geo.size)
                        alarmGridView(fullSize: geo.size)
                        targetGridView(fullSize: geo.size)
                        scrollGridView(fullSize: geo.size).padding(.leading, Config.yGridPadding)
                    }
                }
            }.frame(height: Config.height)
        }
    }
    
    private func targetGridView(fullSize: CGSize) -> some View {
        Path { path in
            if let targetValue = targetValue {
                let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(targetValue))

                path.move(to: CGPoint(x: Config.yGridPadding, y: y))
                path.addLine(to: CGPoint(x: fullSize.width, y: y))
            }
        }
        .stroke(style: Config.targetStrokeStyle)
        .stroke(Config.targetGridColor)
    }
    
    private func alarmGridView(fullSize: CGSize) -> some View {
        Path { path in
            if let alarmLow = alarmLow {
                let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(alarmLow))

                path.move(to: CGPoint(x: Config.yGridPadding, y: y))
                path.addLine(to: CGPoint(x: fullSize.width, y: y))
            }

            if let alarmHigh = alarmHigh {
                let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(alarmHigh))

                path.move(to: CGPoint(x: Config.yGridPadding, y: y))
                path.addLine(to: CGPoint(x: fullSize.width, y: y))
            }
        }
        .stroke(style: Config.alarmStrokeStyle)
        .stroke(Config.alarmGridColor)
    }

    private func yGridView(fullSize: CGSize) -> some View {
        ZStack {
            let gridParts = stride(from: Config.minGlucose, to: Config.maxGlucose + 1, by: Config.yStep)

            Path { path in
                for i in gridParts {
                    if i == targetValue || i == alarmLow || i == alarmHigh {
                        continue
                    }
                    
                    let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(i))

                    path.move(to: CGPoint(x: Config.yGridPadding, y: y))
                    path.addLine(to: CGPoint(x: fullSize.width, y: y))
                }
            }
            .stroke(style: Config.yGridStrokeStyle)
            .stroke(Config.yGridColor)

            ForEach(Array(gridParts), id: \.self) { i in
                let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(i))

                Text(i.asGlucose(unit: glucoseUnit))
                    .font(.system(size: Config.yGridFontSize))
                    .fontWeight(.light)
                    .padding(0)
                    .frame(width: Config.yGridFontWidth, alignment: .trailing)
                    .position(x: 0, y: y)
            }
        }
    }
    
    private func xGridView(fullSize: CGSize) -> some View {
        ZStack {
            if let first = firstTimestamp, let last = lastTimeStamp {
                let allHours = Date.dates(from: first.rounded(on: 15, .minute).addingTimeInterval(-1 * 30 * 60), to: last.addingTimeInterval(30 * 60))
                
                ForEach(Array(allHours), id: \.self) { hour in
                    Text(hour.localTime)
                        .font(.system(size: Config.xGridFontSize))
                        .fontWeight(.light)
                        .position(x: timestampToX(timeStamp: hour), y: fullSize.height - Config.yGridFontSize)
                }
                
                Path { path in
                    for hour in allHours {
                        path.move(to: CGPoint(x: timestampToX(timeStamp: hour), y: 0))
                        path.addLine(to: CGPoint(x: timestampToX(timeStamp: hour), y: fullSize.height - Config.yAdditionalBottom))
                    }
                }
                .stroke(style: Config.xGridStrokeStyle)
                .stroke(Config.xGridColor)
            }
        }
    }

    private func scrollGridView(fullSize: CGSize) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scroll in
                ZStack {
                    xGridView(fullSize: fullSize)
                    glucoseDotsGridView(fullSize: fullSize)
                }
                .id(Config.endID)
                .frame(width: CGFloat(glucoseMinutes) * Config.xStep)
                .onChange(of: glucoseValues) { _ in
                    scroll.scrollTo(Config.endID, anchor: .trailing)
                }
                .onAppear {
                    DispatchQueue.main.async {
                        scroll.scrollTo(Config.endID, anchor: .trailing)
                    }
                }
            }
        }
    }
    
    private func glucoseDotsGridView(fullSize: CGSize) -> some View {
        Path { path in
            for value in glucoseValues {
                let x = timestampToX(timeStamp: value.timeStamp)
                let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(value.glucoseFiltered))

                path.addEllipse(in: CGRect(x: x - Config.dotSize / 2, y: y - Config.dotSize / 2, width: Config.dotSize, height: Config.dotSize))
            }

        }.fill(dotColor)
    }
}

struct GlucoseChartView_Previews: PreviewProvider {
    static var previews: some View {
        let dateFormatter = ISO8601DateFormatter()
        
        let glucoseValues = [
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T10:00:00+0200")!, glucose: 70),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T10:15:00+0200")!, glucose: 100),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T10:30:00+0200")!, glucose: 180),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T10:45:00+0200")!, glucose: 250),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T11:00:00+0200")!, glucose: 70),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T11:05:00+0200")!, glucose: 100),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T11:10:00+0200")!, glucose: 180),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T11:15:00+0200")!, glucose: 250),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T12:00:00+0200")!, glucose: 70),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T12:01:00+0200")!, glucose: 70),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T12:02:00+0200")!, glucose: 70),
            SensorGlucose(timeStamp: dateFormatter.date(from: "2021-08-01T12:03:00+0200")!, glucose: 70)
        ]

        ForEach(ColorScheme.allCases, id: \.self) {
            GlucoseChartView(glucoseValues: glucoseValues, glucoseUnit: .mgdL, alarmLow: 70, alarmHigh: 180, targetValue: 100).preferredColorScheme($0)
            GlucoseChartView(glucoseValues: glucoseValues, glucoseUnit: .mmolL, alarmLow: 70, alarmHigh: 180, targetValue: 100).preferredColorScheme($0)
        }
    }
}
