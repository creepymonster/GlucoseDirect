//
//  GlucoseChartView.swift
//  LibreDirect
//

import Accelerate
import Combine
import SwiftUI

// MARK: - Glucose + Equatable

extension Glucose: Equatable {
    static func == (lhs: Glucose, rhs: Glucose) -> Bool {
        lhs.timestamp == rhs.timestamp
    }
}

extension Date {
    static func dates(from fromDate: Date, to toDate: Date, step: Int) -> [Date] {
        var dates: [Date] = []
        var date = fromDate

        while date <= toDate {
            dates.append(date)
            guard let newDate = Calendar.current.date(byAdding: .minute, value: step, to: date) else {
                break
            }
            date = newDate
        }

        return dates
    }
}

// MARK: - TextInfo

struct TextInfo {
    let description: String
    let x: CGFloat
    let y: CGFloat
    let highlight: Bool
}

// MARK: - SizePreferenceKey

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// MARK: - ChartView

struct ChartView: View {
    @EnvironmentObject var store: AppStore

    @Environment(\.colorScheme) var colorScheme

    @StateObject private var updater = MinuteUpdater()
    @State var alarmHighGridPath = Path()
    @State var alarmLowGridPath = Path()
    @State var firstTimeStamp: Date? = nil
    @State var cgmPath = Path()
    @State var bgmPath = Path()
    @State var glucoseSteps: Int = 0
    @State var lastTimeStamp: Date? = nil
    @State var targetGridPath = Path()
    @State var xGridPath = Path()
    @State var xGridTexts: [TextInfo] = []
    @State var yGridPath = Path()
    @State var yGridTexts: [TextInfo] = []
    @State var deviceOrientation = UIDevice.current.orientation
    @State var deviceColorScheme = ColorScheme.light
    @State var cgmValues: [Glucose] = []
    @State var bgmValues: [Glucose] = []

    @State var zoomMinutes = 1
    @State var zoomGridStep = Config.zoomGridStep[1]!

    var chartView: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                yGridView()
                alarmLowGridView()
                alarmHighGridView()
                targetGridView()
                scrollGridView(fullSize: geo.size).padding(.leading, Config.y.padding)
            }
            .gesture(TapGesture(count: 2).onEnded { _ in
                store.dispatch(.setChartShowLines(enabled: !store.state.chartShowLines))
            })
            .onChange(of: colorScheme) { scheme in
                if deviceColorScheme != scheme {
                    AppLog.info("onChange colorScheme: \(scheme)")

                    deviceColorScheme = scheme
                }
            }
            .onRotate { rotation in
                if deviceOrientation != rotation {
                    deviceOrientation = rotation

                    AppLog.info("onRotate, isPortrait: \(rotation.isPortrait)")

                    updateYGrid(fullSize: geo.size, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: store.state.targetValue, glucoseUnit: store.state.glucoseUnit)
                    updateAlarmLowGrid(fullSize: geo.size, alarmLow: store.state.alarmLow)
                    updateAlarmHighGrid(fullSize: geo.size, alarmHigh: store.state.alarmHigh)
                    updateTargetGrid(fullSize: geo.size, targetValue: store.state.targetValue)
                }
            }
            .onChange(of: store.state.chartShowLines) { chartShowLines in
                AppLog.info("onChange chartShowLines: \(chartShowLines)")

                updateCgmPath(fullSize: geo.size, glucoseValues: cgmValues)
                updateBgmPath(fullSize: geo.size, glucoseValues: bgmValues)
            }
            .onChange(of: store.state.alarmLow) { alarmLow in
                AppLog.info("onChange alarmLow: \(alarmLow)")

                updateYGrid(fullSize: geo.size, alarmLow: alarmLow, alarmHigh: store.state.alarmHigh, targetValue: store.state.targetValue, glucoseUnit: store.state.glucoseUnit)
                updateAlarmLowGrid(fullSize: geo.size, alarmLow: alarmLow)
            }
            .onChange(of: store.state.alarmHigh) { alarmHigh in
                AppLog.info("onChange alarmHigh: \(alarmHigh)")

                updateYGrid(fullSize: geo.size, alarmLow: store.state.alarmLow, alarmHigh: alarmHigh, targetValue: store.state.targetValue, glucoseUnit: store.state.glucoseUnit)
                updateAlarmHighGrid(fullSize: geo.size, alarmHigh: alarmHigh)
            }
            .onChange(of: store.state.targetValue) { targetValue in
                AppLog.info("onChange targetValue: \(targetValue)")

                updateYGrid(fullSize: geo.size, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: targetValue, glucoseUnit: store.state.glucoseUnit)
                updateTargetGrid(fullSize: geo.size, targetValue: targetValue)
            }
            .onChange(of: store.state.glucoseUnit) { glucoseUnit in
                AppLog.info("onChange glucoseUnit: \(glucoseUnit)")

                updateYGrid(fullSize: geo.size, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: store.state.targetValue, glucoseUnit: glucoseUnit)
            }
            .onChange(of: store.state.glucoseValues) { _ in
                AppLog.info("onChange glucoseValues: \(store.state.glucoseValues.count)")

                updateGlucoseValues()
                updateHelpVariables(fullSize: geo.size, glucoseValues: store.state.glucoseValues)

                updateXGrid(fullSize: geo.size, firstTimeStamp: self.firstTimeStamp, lastTimeStamp: self.lastTimeStamp)

                updateCgmPath(fullSize: geo.size, glucoseValues: cgmValues)
                updateBgmPath(fullSize: geo.size, glucoseValues: bgmValues)
            }
            .onChange(of: zoomMinutes) { _ in
                updateGlucoseValues()
                updateHelpVariables(fullSize: geo.size, glucoseValues: store.state.glucoseValues)

                updateYGrid(fullSize: geo.size, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: store.state.targetValue, glucoseUnit: store.state.glucoseUnit)
                updateXGrid(fullSize: geo.size, firstTimeStamp: self.firstTimeStamp, lastTimeStamp: self.lastTimeStamp)

                updateAlarmLowGrid(fullSize: geo.size, alarmLow: store.state.alarmLow)
                updateAlarmHighGrid(fullSize: geo.size, alarmHigh: store.state.alarmHigh)
                updateTargetGrid(fullSize: geo.size, targetValue: store.state.targetValue)

                updateCgmPath(fullSize: geo.size, glucoseValues: cgmValues)
                updateBgmPath(fullSize: geo.size, glucoseValues: bgmValues)
            }
            .onAppear {
                AppLog.info("onAppear")

                updateGlucoseValues()
                updateHelpVariables(fullSize: geo.size, glucoseValues: store.state.glucoseValues)

                updateYGrid(fullSize: geo.size, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh, targetValue: store.state.targetValue, glucoseUnit: store.state.glucoseUnit)
                updateXGrid(fullSize: geo.size, firstTimeStamp: self.firstTimeStamp, lastTimeStamp: self.lastTimeStamp)

                updateAlarmLowGrid(fullSize: geo.size, alarmLow: store.state.alarmLow)
                updateAlarmHighGrid(fullSize: geo.size, alarmHigh: store.state.alarmHigh)
                updateTargetGrid(fullSize: geo.size, targetValue: store.state.targetValue)

                updateCgmPath(fullSize: geo.size, glucoseValues: cgmValues)
                updateBgmPath(fullSize: geo.size, glucoseValues: bgmValues)
            }
        }
    }

    var body: some View {
        if !store.state.glucoseValues.isEmpty {
            Section(
                content: {
                    chartView
                        .padding(.leading, 5)
                        .padding(.trailing, 0)
                        .padding(.top, 15)
                        .padding(.bottom, 5)
                        .frame(height: Config.height)

                    HStack {
                        ForEach(Config.zoomLevels, id: \.minutes) { zoom in
                            Spacer()
                            Button(
                                action: {
                                    zoomMinutes = zoom.minutes
                                    zoomGridStep = Config.zoomGridStep[zoom.minutes]!
                                },
                                label: {
                                    Circle()
                                        .if(zoomMinutes == zoom.minutes) {
                                            $0.fill(Config.y.textColor)
                                        } else: {
                                            $0.stroke(Config.y.textColor)
                                        }
                                        .frame(width: 9, height: 9)

                                    Text(zoom.title)
                                        .foregroundColor(Config.y.textColor)
                                }
                            ).buttonStyle(.plain)
                        }
                        Spacer()
                    }
                },
                header: {
                    Label(String(format: LocalizedString("Chart (%1$@)"), store.state.glucoseValues.count), systemImage: "chart.bar.xaxis")
                }
            )
        }
    }

    private func scrollGridView(fullSize: CGSize) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scroll in
                ZStack {
                    xGridView()

                    nowView(fullSize: fullSize)
                        .zIndex(2)

                    if store.state.chartShowLines {
                        cgmLineView()
                            .zIndex(3)
                    } else {
                        cgmDotsView()
                            .zIndex(3)
                    }

                    bgmDotsView().zIndex(4)
                }
                .frame(width: CGFloat(Double(glucoseSteps) * Config.x.stepWidth))
                .onChange(of: cgmValues) { _ in
                    scroll.scrollTo(Config.endID, anchor: .trailing)
                }
                .onChange(of: bgmValues) { _ in
                    scroll.scrollTo(Config.endID, anchor: .trailing)
                }
                .onChange(of: zoomMinutes) { _ in
                    scroll.scrollTo(Config.endID, anchor: .trailing)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                        scroll.scrollTo(Config.endID, anchor: .trailing)
                    }
                }
            }
        }
    }

    private func alarmHighGridView() -> some View {
        alarmHighGridPath
            .stroke(style: Config.alarm.strokeStyle)
            .stroke(Config.alarm.color)
    }

    private func alarmLowGridView() -> some View {
        alarmLowGridPath
            .stroke(style: Config.alarm.strokeStyle)
            .stroke(Config.alarm.color)
    }

    private func nowView(fullSize: CGSize) -> some View {
        Path { path in
            #if targetEnvironment(simulator)
                let now = ISO8601DateFormatter().date(from: "2021-08-01T11:50:00+0200") ?? Date()
            #else
                let now = Date().rounded(on: 1, .minute)
            #endif

            let x = self.translateTimeStampToX(timestamp: now)

            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: fullSize.height - Config.y.additionalBottom))
        }
        .stroke(style: Config.now.strokeStyle)
        .stroke(Config.now.color)
    }

    private func cgmLineView() -> some View {
        cgmPath
            .stroke(Config.line.cgmColor, lineWidth: Config.line.size)
    }

    private func cgmDotsView() -> some View {
        cgmPath
            .fill(Config.dot.cgmColor)
    }

    private func bgmLineView() -> some View {
        bgmPath
            .stroke(Config.line.bgmColor, lineWidth: Config.line.size)
    }

    private func bgmDotsView() -> some View {
        bgmPath
            .fill(Config.dot.bgmColor)
    }

    private func targetGridView() -> some View {
        targetGridPath
            .stroke(style: Config.target.strokeStyle)
            .stroke(Config.target.color)
    }

    private func xGridView() -> some View {
        ZStack {
            xGridPath
                .stroke(style: Config.x.strokeStyle)
                .stroke(Config.x.color)

            ForEach(xGridTexts, id: \.self.x) { text in
                let fontWeight: Font.Weight = text.highlight ? .semibold : .regular

                Text(text.description)
                    .foregroundColor(Config.x.textColor)
                    .font(.system(size: Config.x.fontSize))
                    .fontWeight(fontWeight)
                    .position(x: text.x, y: text.y)
                    .if(text.x == xGridTexts.last?.x) { $0.id(Config.endID) }
            }
        }
    }

    private func yGridView() -> some View {
        ZStack {
            yGridPath
                .stroke(style: Config.y.strokeStyle)
                .stroke(Config.y.color)

            ForEach(yGridTexts, id: \.self.y) { text in
                let fontWeight: Font.Weight = text.highlight ? .semibold : .regular

                Text(text.description)
                    .foregroundColor(Config.y.textColor)
                    .font(.system(size: Config.y.fontSize))
                    .fontWeight(fontWeight)
                    .padding(0)
                    .frame(width: Config.y.fontWidth, alignment: .trailing)
                    .position(x: text.x, y: text.y)
            }
        }
    }

    private func updateGlucoseValues() {
        if zoomMinutes == 1 {
            cgmValues = store.state.glucoseValues.filter { value in
                value.type == .cgm && value.quality == .OK
            }

            bgmValues = store.state.glucoseValues.filter { value in
                value.type == .bgm && value.quality == .OK
            }
        } else {
            // cgm values
            let filteredValues = store.state.glucoseValues.filter { value in
                value.type == .cgm && value.quality == .OK
            }.map { value in
                (value.timestamp.rounded(on: zoomMinutes, .minute), value.glucoseValue!)
            }

            let groupedValues = Dictionary(grouping: filteredValues, by: { $0.0 })
            cgmValues = groupedValues.map { group in
                let sumGlucoseValues = group.value.reduce(0) {
                    $0 + $1.1
                }

                let meanGlucoseValues = sumGlucoseValues / group.value.count

                return Glucose(id: UUID(), timestamp: group.key, glucose: meanGlucoseValues, type: .cgm)
            }.sorted(by: { $0.timestamp < $1.timestamp })

            // bgm values
            bgmValues = store.state.glucoseValues.filter { value in
                value.type == .bgm && value.quality == .OK
            }.map { value in
                Glucose(id: value.id, timestamp: value.timestamp.rounded(on: zoomMinutes, .minute), glucose: value.glucoseValue!, type: .bgm)
            }
        }
    }

    private func updateHelpVariables(fullSize: CGSize, glucoseValues: [Glucose]) {
        AppLog.info("updateHelpVariables")

        if let first = glucoseValues.first, let last = glucoseValues.last {
            let firstTimeStamp = first.timestamp.addingTimeInterval(-2 * zoomGridStep * 60)

            #if targetEnvironment(simulator)
                let lastTimeStamp = last.timestamp.addingTimeInterval(2 * zoomGridStep * 60)
            #else
                let lastTimeStamp = Date().rounded(on: 1, .minute).addingTimeInterval(2 * zoomGridStep * 60)
            #endif

            let glucoseSteps = Int(firstTimeStamp.distance(to: lastTimeStamp) / 60) / zoomMinutes

            self.firstTimeStamp = firstTimeStamp
            self.lastTimeStamp = lastTimeStamp
            self.glucoseSteps = glucoseSteps
        }
    }

    private func updateAlarmHighGrid(fullSize: CGSize, alarmHigh: Int?) {
        AppLog.info("updateAlarmHighGrid")

        calculationQueue.async {
            if let alarmHigh = alarmHigh {
                let alarmHighGridPath = Path { path in
                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(alarmHigh))

                    path.move(to: CGPoint(x: Config.y.padding, y: y))
                    path.addLine(to: CGPoint(x: fullSize.width, y: y))
                }

                DispatchQueue.main.async {
                    self.alarmHighGridPath = alarmHighGridPath
                }
            }
        }
    }

    private func updateAlarmLowGrid(fullSize: CGSize, alarmLow: Int?) {
        AppLog.info("updateAlarmLowGrid")

        calculationQueue.async {
            if let alarmLow = alarmLow {
                let alarmLowGridPath = Path { path in
                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(alarmLow))

                    path.move(to: CGPoint(x: Config.y.padding, y: y))
                    path.addLine(to: CGPoint(x: fullSize.width, y: y))
                }

                DispatchQueue.main.async {
                    self.alarmLowGridPath = alarmLowGridPath
                }
            }
        }
    }

    private func updateCgmPath(fullSize: CGSize, glucoseValues: [Glucose]) {
        AppLog.info("updateCgmPath")

        var isFirst = true

        calculationQueue.async {
            let cgmPath = Path { path in
                for glucose in glucoseValues {
                    guard let glucoseValue = glucose.glucoseValue else {
                        return
                    }

                    let x = self.translateTimeStampToX(timestamp: glucose.timestamp)
                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(glucoseValue))

                    if store.state.chartShowLines {
                        if isFirst {
                            isFirst = false
                            path.move(to: CGPoint(x: x, y: y))
                        }

                        path.addLine(to: CGPoint(x: x, y: y))
                    } else {
                        path.addEllipse(in: CGRect(x: x - Config.dot.size / 2, y: y - Config.dot.size / 2, width: Config.dot.size, height: Config.dot.size))
                    }
                }
            }

            DispatchQueue.main.async {
                self.cgmPath = cgmPath
            }
        }
    }

    private func updateBgmPath(fullSize: CGSize, glucoseValues: [Glucose]) {
        AppLog.info("updateBgmPath")

        var isFirst = true

        calculationQueue.async {
            let cgmPath = Path { path in
                for glucose in glucoseValues {
                    guard let glucoseValue = glucose.glucoseValue else {
                        return
                    }

                    let x = self.translateTimeStampToX(timestamp: glucose.timestamp)
                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(glucoseValue))

                    if store.state.chartShowLines {
                        if isFirst {
                            isFirst = false
                            path.move(to: CGPoint(x: x, y: y))
                        }

                        path.addLine(to: CGPoint(x: x, y: y))
                    } else {
                        path.addEllipse(in: CGRect(x: x - Config.dot.size / 2, y: y - Config.dot.size / 2, width: Config.dot.size, height: Config.dot.size))
                    }
                }
            }

            DispatchQueue.main.async {
                self.bgmPath = cgmPath
            }
        }
    }

    private func updateTargetGrid(fullSize: CGSize, targetValue: Int?) {
        AppLog.info("updateTargetGrid")

        calculationQueue.async {
            if let targetValue = targetValue {
                let targetGridPath = Path { path in
                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(targetValue))

                    path.move(to: CGPoint(x: Config.y.padding, y: y))
                    path.addLine(to: CGPoint(x: fullSize.width, y: y))
                }

                DispatchQueue.main.async {
                    self.targetGridPath = targetGridPath
                }
            }
        }
    }

    private func updateXGrid(fullSize: CGSize, firstTimeStamp: Date?, lastTimeStamp: Date?) {
        AppLog.info("updateXGrid")

        calculationQueue.async {
            if let firstTimeStamp = firstTimeStamp, let lastTimeStamp = lastTimeStamp {
                let allHours = Date.dates(
                    from: firstTimeStamp.rounded(on: Int(zoomGridStep), .minute).addingTimeInterval(-3600),
                    to: lastTimeStamp.rounded(on: Int(zoomGridStep), .minute).addingTimeInterval(3600),
                    step: Int(zoomGridStep)
                )

                let xGridPath = Path { path in
                    for hour in allHours {
                        if hour == Date().rounded(on: 1, .minute) {
                            continue
                        }

                        path.move(to: CGPoint(x: self.translateTimeStampToX(timestamp: hour), y: 0))
                        path.addLine(to: CGPoint(x: self.translateTimeStampToX(timestamp: hour), y: fullSize.height - Config.y.additionalBottom))
                    }
                }

                var xGridTexts: [TextInfo] = []
                for hour in allHours {
                    let highlight = Calendar.current.component(.minute, from: hour) == 0
                    let x = self.translateTimeStampToX(timestamp: hour)
                    let y = fullSize.height - Config.y.fontSize
                    xGridTexts.append(TextInfo(description: hour.localTime, x: x, y: y, highlight: highlight))
                }

                DispatchQueue.main.async {
                    self.xGridPath = xGridPath
                    self.xGridTexts = xGridTexts
                }
            }
        }
    }

    private func updateYGrid(fullSize: CGSize, alarmLow: Int?, alarmHigh: Int?, targetValue: Int?, glucoseUnit: GlucoseUnit) {
        AppLog.info("updateYGrid")

        calculationQueue.async {
            let gridParts = store.state.glucoseUnit == .mgdL
                ? Config.y.mgdLGrid
                : Config.y.mmolLGrid

            let yGridPath = Path { path in
                for i in gridParts {
                    if i == alarmLow || i == alarmHigh || i == targetValue {
                        continue
                    }

                    let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(i))

                    path.move(to: CGPoint(x: Config.y.padding, y: y))
                    path.addLine(to: CGPoint(x: fullSize.width, y: y))
                }
            }

            var yGridTexts: [TextInfo] = []
            for i in gridParts {
                if i < AppConfig.minReadableGlucose {
                    continue
                }

                let y = self.translateGlucoseToY(fullSize: fullSize, glucose: CGFloat(i))
                yGridTexts.append(TextInfo(description: i.asGlucose(unit: glucoseUnit), x: 0, y: y, highlight: false))
            }

            DispatchQueue.main.async {
                self.yGridPath = yGridPath
                self.yGridTexts = yGridTexts
            }
        }
    }

    private func translateGlucoseToY(fullSize: CGSize, glucose: CGFloat) -> CGFloat {
        let inMin = CGFloat(Config.minGlucose)
        let inMax = CGFloat(Config.maxGlucose)
        let outMin = fullSize.height - Config.y.additionalBottom
        let outMax = CGFloat(0)

        let y = (glucose - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
        return y
    }

    private func translateStepsToX(steps: Int) -> CGFloat {
        return CGFloat(steps) * CGFloat(Config.x.stepWidth)
    }

    private func translateTimeStampToX(timestamp: Date) -> CGFloat {
        if let first = firstTimeStamp {
            let steps = Int(first.distance(to: timestamp) / 60) / zoomMinutes

            return translateStepsToX(steps: steps)
        }

        return 0
    }

    private enum Config {
        enum alarm {
            static let strokeStyle = StrokeStyle(lineWidth: lineWidth)

            static var color: Color { Color.ui.red.opacity(opacity) }
        }

        enum target {
            static let strokeStyle = StrokeStyle(lineWidth: lineWidth)

            static var color: Color { Color.ui.green.opacity(opacity) }
        }

        enum now {
            static let strokeStyle = StrokeStyle(lineWidth: lineWidth, dash: [4, 8])

            static var color: Color { Color.ui.blue.opacity(opacity) }
        }

        enum dot {
            static let size: CGFloat = 3.5

            static var cgmColor: Color { Color(hex: "#36454F") | Color(hex: "#E5E4E2") }
            static var bgmColor: Color { Color.ui.red }
        }

        enum line {
            static var size = 2.5

            static var cgmColor: Color { Color(hex: "#36454F") | Color(hex: "#E5E4E2") }
            static var bgmColor: Color { Color.ui.red }
        }

        enum x {
            static let fontSize: CGFloat = 12
            static let strokeStyle = StrokeStyle(lineWidth: lineWidth)
            static let stepWidth: Double = 5

            static var color: Color { Color(hex: "#E4E6EB") | Color(hex: "#404040") } // .opacity(opacity)
            static var textColor: Color { Color(hex: "#181818") | Color(hex: "#A0A0A0") }
        }

        enum y {
            static let additionalBottom: CGFloat = fontSize * 2
            static let fontSize: CGFloat = 12
            static let fontWidth: CGFloat = 28
            static let padding: CGFloat = 20
            static let strokeStyle = StrokeStyle(lineWidth: lineWidth)

            static let mgdLGrid: [Int] = [0, 50, 100, 150, 200, 250, 300, 350]
            static let mmolLGrid: [Int] = [0, 54, 108, 162, 216, 270, 324]

            static var color: Color { Color(hex: "#E4E6EB") | Color(hex: "#404040") }
            static var textColor: Color { Color(hex: "#181818") | Color(hex: "#A0A0A0") }
        }

        static let zoomGridStep: [Int: Double] = [
            1: 15,
            5: 60,
            15: 180,
            30: 360,
        ]

        static let zoomLevels: [ZoomLevel] = [
            ZoomLevel(minutes: 1, title: "1m"),
            ZoomLevel(minutes: 5, title: "5m"),
            ZoomLevel(minutes: 15, title: "15m"),
            ZoomLevel(minutes: 30, title: "30m"),
        ]

        static let endID = "End"
        static let height: CGFloat = 350
        static let lineWidth = 0.1
        static let maxGlucose = 350
        static let minGlucose = 0
        static let opacity = 0.5

        static var backgroundColor: Color { Color(hex: "#F5F5F5") | Color(hex: "#181818") }
    }

    private let calculationQueue = DispatchQueue(label: "libre-direct.chart-calculation")
}

// MARK: - ZoomLevel

struct ZoomLevel {
    let minutes: Int
    let title: String
}

// MARK: - MinuteUpdater

class MinuteUpdater: ObservableObject {
    // MARK: Lifecycle

    init() {
        let fireDate = Date().rounded(on: 1, .minute).addingTimeInterval(60)
        AppLog.info("MinuteUpdater, init with \(fireDate)")

        let timer = Timer(fire: fireDate, interval: 60, repeats: true) { _ in
            AppLog.info("MinuteUpdater, fires at \(Date())")
            self.objectWillChange.send()
        }
        RunLoop.main.add(timer, forMode: .common)

        self.timer = timer
    }

    // MARK: Internal

    var timer: Timer?
}

// MARK: - ChartView_Previews

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            ChartView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
