//
//  GlucoseChartView.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 26.07.21.
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
            guard let newDate = Calendar.current.date(byAdding: .hour, value: 1, to: date) else {
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
        static let darkDotColor = Color.white
        static let dotSize: CGFloat = 3.5
        static let endID = "End"
        static let height: CGFloat = 350
        static let lightDotColor = Color.black
        static let maxGlucose = 400
        static let minGlucose = 0
        static let targetGridColor = Color.green.opacity(0.5)
        static let targetStrokeStyle = StrokeStyle(lineWidth: 0.2, dash: [5])
        static let xAdditionalLeft: CGFloat = Config.xGridFontSize * 2
        static let xAdditionalRight: CGFloat = 50
        static let xGridColor = Color.secondary.opacity(0.25)
        static let xGridFontSize: CGFloat = 12
        static let xGridStrokeStyle = StrokeStyle(lineWidth: 0.2)
        static let xStep: CGFloat = Config.dotSize + Config.dotSize / 2
        static let yAdditionalBottom: CGFloat = Config.yGridFontSize * 2
        static let yGridColor = Color.secondary.opacity(0.25)
        static let yGridFontSize: CGFloat = 12
        static let yGridStrokeStyle = StrokeStyle(lineWidth: 0.2)
        static let yStep = 50
    }
    
    @Environment(\.colorScheme) var colorScheme

    var glucoseValues: [SensorGlucose]
    var alarmLow: Int?
    var alarmHigh: Int?
    var targetValue: Int?

    var glucoseMinutes: Int {
        get {
            if let first = glucoseValues.first, let last = glucoseValues.last {
                return Int(first.timeStamp.distance(to: last.timeStamp) / 60)
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
        if let first = glucoseValues.first {
            return CGFloat(first.timeStamp.distance(to: timeStamp) / 60) * Config.xStep
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
            GroupBox(label: Text(String(format: LocalizedString("Chart (%1$@)", comment: ""), glucoseValues.count.description)).padding(.bottom).foregroundColor(.accentColor)) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        yGridView(fullSize: geo.size)
                        alarmGridView(fullSize: geo.size)
                        targetGridView(fullSize: geo.size)
                        scrollGridView(fullSize: geo.size).padding(.leading, Config.xAdditionalLeft)
                    }
                }
            }.frame(height: Config.height)
        }
    }
    
    private func targetGridView(fullSize: CGSize) -> some View {
        Path { path in
            if let targetValue = targetValue {
                let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(targetValue))

                path.move(to: CGPoint(x: Config.xAdditionalLeft, y: y))
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

                path.move(to: CGPoint(x: Config.xAdditionalLeft, y: y))
                path.addLine(to: CGPoint(x: fullSize.width, y: y))
            }

            if let alarmHigh = alarmHigh {
                let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(alarmHigh))

                path.move(to: CGPoint(x: Config.xAdditionalLeft, y: y))
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

                    path.move(to: CGPoint(x: Config.xAdditionalLeft, y: y))
                    path.addLine(to: CGPoint(x: fullSize.width, y: y))
                }
            }
            .stroke(style: Config.yGridStrokeStyle)
            .stroke(Config.yGridColor)

            ForEach(Array(gridParts), id: \.self) { i in
                let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(i))

                Text("\(i)")
                    .font(.system(size: Config.yGridFontSize))
                    .fontWeight(.light)
                    .frame(width: Config.xAdditionalLeft, alignment: .trailing)
                    .position(x: 0, y: y)
            }
        }
    }
    
    private func xGridView(fullSize: CGSize) -> some View {
        ZStack {
            let firstTimeStamp = glucoseValues.first!.timeStamp.rounded(on: 1, .hour)
            let lastTimeStamp = glucoseValues.last!.timeStamp.rounded(on: 1, .hour)
            let allHours = Date.dates(from: firstTimeStamp, to: lastTimeStamp)
            
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

    private func scrollGridView(fullSize: CGSize) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scroll in
                ZStack {
                    xGridView(fullSize: fullSize)
                    glucoseDotsGridView(fullSize: fullSize)
                }
                .id(Config.endID)
                .frame(width: CGFloat(glucoseMinutes) * Config.xStep + Config.xAdditionalLeft + Config.xAdditionalRight)
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
    
    private func glucoseLineGridView(fullSize: CGSize) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: glucoseToY(fullSize: fullSize, glucose: CGFloat(glucoseValues.first!.glucoseFiltered))))
            
            for value in glucoseValues {
                let x = timestampToX(timeStamp: value.timeStamp) + Config.dotSize / 2
                let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(value.glucoseFiltered))

                path.addLine(to: CGPoint(x: x, y: y))
            }

        }.stroke(dotColor)
    }
    
    private func glucoseDotsGridView(fullSize: CGSize) -> some View {
        Path { path in
            for value in glucoseValues {
                let x = timestampToX(timeStamp: value.timeStamp) + Config.dotSize / 2
                let y = glucoseToY(fullSize: fullSize, glucose: CGFloat(value.glucoseFiltered))

                path.addEllipse(in: CGRect(x: x - Config.dotSize / 2, y: y - Config.dotSize / 2, width: Config.dotSize, height: Config.dotSize))
            }

        }.fill(dotColor)
    }
}

struct GlucoseChartView_Previews: PreviewProvider {
    static var previews: some View {
        let glucoseValues = [
            SensorGlucose(timeStamp: Date().addingTimeInterval(180 * 60 * -1), glucose: 70),
            SensorGlucose(timeStamp: Date().addingTimeInterval(175 * 60 * -1), glucose: 100),
            SensorGlucose(timeStamp: Date().addingTimeInterval(170 * 60 * -1), glucose: 180),

            SensorGlucose(timeStamp: Date().addingTimeInterval(120 * 60 * -1), glucose: 185),
            SensorGlucose(timeStamp: Date().addingTimeInterval(110 * 60 * -1), glucose: 180),
            SensorGlucose(timeStamp: Date().addingTimeInterval(100 * 60 * -1), glucose: 170),
            SensorGlucose(timeStamp: Date().addingTimeInterval(95 * 60 * -1), glucose: 165),
            SensorGlucose(timeStamp: Date().addingTimeInterval(90 * 60 * -1), glucose: 150),
            SensorGlucose(timeStamp: Date().addingTimeInterval(85 * 60 * -1), glucose: 120),
            SensorGlucose(timeStamp: Date().addingTimeInterval(70 * 60 * -1), glucose: 125),
            SensorGlucose(timeStamp: Date().addingTimeInterval(55 * 60 * -1), glucose: 130),
            SensorGlucose(timeStamp: Date().addingTimeInterval(40 * 60 * -1), glucose: 125),
            SensorGlucose(timeStamp: Date().addingTimeInterval(35 * 60 * -1), glucose: 120),
            SensorGlucose(timeStamp: Date().addingTimeInterval(20 * 60 * -1), glucose: 115),
            SensorGlucose(timeStamp: Date().addingTimeInterval(0 * 60 * -1), glucose: 105)
        ]

        ForEach(ColorScheme.allCases, id: \.self) {
            GlucoseChartView(glucoseValues: glucoseValues, alarmLow: 70, alarmHigh: 180, targetValue: 100).preferredColorScheme($0)
        }
    }
}
