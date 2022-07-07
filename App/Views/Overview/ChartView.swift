//
//  GlucoseChartView.swift
//  GlucoseDirect
//

import Charts
import SwiftUI

// MARK: - ChartView

@available(iOS 16.0, *)
struct ChartView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore
    @Environment(\.scenePhase) var scenePhase

    var zoomLevel: ZoomLevel? {
        Config.zoomLevels.first(where: { $0.level == store.state.chartZoomLevel })
    }

    var glucoseUnit: GlucoseUnit {
        store.state.glucoseUnit
    }

    var labelEveryUnit: Calendar.Component {
        if let zoomLevel = zoomLevel {
            return zoomLevel.labelEveryUnit
        }

        return .hour
    }

    var labelEvery: Int {
        if let zoomLevel = zoomLevel {
            return zoomLevel.labelEvery
        }

        return 1
    }

    var alarmLow: Decimal {
        if glucoseUnit == .mmolL {
            return store.state.alarmLow.asMmolL
        }

        return store.state.alarmLow.asMgdL
    }

    var alarmHigh: Decimal {
        if glucoseUnit == .mmolL {
            return store.state.alarmHigh.asMmolL
        }

        return store.state.alarmHigh.asMgdL
    }

    var glucoseValues: [Glucose] {
        store.state.glucoseValues
    }

    var ChartView: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geometryProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollViewProxy in
                        Chart {
                            if let firstTimestamp = glucoseValues.first?.timestamp {
                                RuleMark(
                                    x: .value("", Calendar.current.date(byAdding: .minute, value: -15, to: firstTimestamp)!)
                                ).foregroundStyle(.clear)
                            }

                            RuleMark(y: .value("Lower limit", alarmLow))
                                .foregroundStyle(Color.ui.orange)
                                .lineStyle(Config.ruleStyle)

                            RuleMark(y: .value("Upper limit", alarmHigh))
                                .foregroundStyle(Color.ui.orange)
                                .lineStyle(Config.ruleStyle)

                            ForEach(cgmSeries) { value in
                                LineMark(
                                    x: .value("Time", value.valueX),
                                    y: .value("Glucose", value.valueY)
                                )
                                .foregroundStyle(Color.ui.blue)
                                .lineStyle(Config.lineStyle)
                            }

                            ForEach(bgmSeries) { value in
                                PointMark(
                                    x: .value("Time", value.valueX),
                                    y: .value("Glucose", value.valueY)
                                )
                                .symbolSize(Config.symbolSize)
                                .foregroundStyle(Color.ui.red)
                            }

                            if let selectedPointInfo = selectedCGMPoint {
                                PointMark(
                                    x: .value("Time", selectedPointInfo.valueX),
                                    y: .value("Glucose", selectedPointInfo.valueY)
                                )
                                .symbolSize(Config.selectionSize)
                                .opacity(0.5)
                                .foregroundStyle(Color.ui.blue)
                            }

                            if let selectedPointInfo = selectedBGMPoint {
                                PointMark(
                                    x: .value("Time", selectedPointInfo.valueX),
                                    y: .value("Glucose", selectedPointInfo.valueY)
                                )
                                .symbolSize(Config.selectionSize)
                                .opacity(0.5)
                                .foregroundStyle(Color.ui.red)
                            }

                            if let lastTimestamp = glucoseValues.last?.timestamp {
                                RuleMark(
                                    x: .value("", Calendar.current.date(byAdding: .minute, value: 15, to: lastTimestamp)!)
                                ).foregroundStyle(.clear)
                            }
                        }
                        .chartPlotStyle { plotArea in
                            plotArea.padding(.vertical)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: labelEveryUnit, count: labelEvery)) { value in
                                if let dateValue = value.as(Date.self) {
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(dateValue.toLocalTime())
                                }
                            }
                        }
                        .id(Config.chartID)
                        .frame(width: max(0, geometryProxy.size.width, seriesWidth))
                        .onChange(of: store.state.glucoseUnit) { glucoseUnit in
                            DirectLog.info("onChange(\(glucoseUnit))")

                            if shouldUpdate() {
                                updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)
                            }

                        }.onChange(of: store.state.glucoseValues) { glucoseValues in
                            DirectLog.info("onChange(\(glucoseValues.count))")

                            if shouldUpdate() {
                                updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)
                            }

                        }.onChange(of: store.state.chartZoomLevel) { chartZoomLevel in
                            DirectLog.info("onChange(\(chartZoomLevel))")

                            if shouldUpdate() {
                                updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)
                            }

                        }.onChange(of: scenePhase) { newScenePhase in
                            DirectLog.info("onChange(\(newScenePhase))")

                            if shouldUpdate(newScenePhase: newScenePhase) {
                                updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)
                            }
                        }.chartOverlay { overlayProxy in
                            GeometryReader { geometryProxy in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .gesture(DragGesture()
                                        .onChanged { value in
                                            let currentX = value.location.x - geometryProxy[overlayProxy.plotAreaFrame].origin.x

                                            if let currentDate: Date = overlayProxy.value(atX: currentX) {
                                                let selectedCGMPoint = cgmPointInfos[currentDate.toRounded(on: 1, .minute)]
                                                let selectedBGMPoint = bgmPointInfos[currentDate.toRounded(on: 1, .minute)]

                                                self.selectedCGMPoint = selectedCGMPoint
                                                self.selectedBGMPoint = selectedBGMPoint
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedCGMPoint = nil
                                            selectedBGMPoint = nil
                                        }
                                    )
                            }
                        }
                    }
                }
            }

            if selectedCGMPoint != nil || selectedBGMPoint != nil {
                HStack {
                    if let selectedCGMPoint = selectedCGMPoint {
                        VStack(alignment: .leading) {
                            Text(selectedCGMPoint.valueX.toLocalDateTime())
                            Text(selectedCGMPoint.info).bold()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundColor(Color.white)
                        .font(.footnote)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .foregroundStyle(Color.ui.blue)
                                .opacity(0.5)
                        )
                    }

                    if let selectedBGMPoint = selectedBGMPoint {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(Color.white)

                            VStack(alignment: .leading) {
                                Text(selectedBGMPoint.valueX.toLocalDateTime())
                                Text(selectedBGMPoint.info).bold()
                            }
                            .foregroundColor(Color.white)
                            .font(.footnote)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .foregroundStyle(Color.ui.red)
                                .opacity(0.5)
                        )
                    }
                }
            }
        }
    }

    var ZoomLevelsView: some View {
        HStack {
            ForEach(Config.zoomLevels, id: \.level) { zoom in
                Button(
                    action: {
                        store.dispatch(.setChartZoomLevel(level: zoom.level))
                    },
                    label: {
                        Circle()
                            .if(isSelectedZoomLevel(level: zoom.level)) {
                                $0.fill(Color.ui.label)
                            } else: {
                                $0.stroke(Color.ui.label)
                            }
                            .frame(width: 12, height: 12)

                        Text(zoom.name)
                            .font(.subheadline)
                            .foregroundColor(Color.ui.label)
                    }
                )
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }

    var body: some View {
        Section(
            content: {
                VStack {
                    ChartView.frame(height: 300)
                    ZoomLevelsView
                }
            },
            header: {
                Label("Chart", systemImage: "chart.xyaxis.line")
            }
        )
    }

    // MARK: Private

    private enum Config {
        static let chartID = "chart"
        static let symbolSize: CGFloat = 15
        static let selectionSize: CGFloat = 100
        static let spacerWidth: CGFloat = 50
        static let lineStyle: StrokeStyle = .init(lineWidth: 3.5, lineCap: .round)
        static let ruleStyle: StrokeStyle = .init(lineWidth: 0.5, dash: [2])

        static let zoomLevels: [ZoomLevel] = [
            ZoomLevel(level: 1, name: LocalizedString("1h"), visibleHours: 1, labelEvery: 30, labelEveryUnit: .minute),
            ZoomLevel(level: 6, name: LocalizedString("6h"), visibleHours: 6, labelEvery: 2, labelEveryUnit: .hour),
            ZoomLevel(level: 12, name: LocalizedString("12h"), visibleHours: 12, labelEvery: 3, labelEveryUnit: .hour),
            ZoomLevel(level: 24, name: LocalizedString("24h"), visibleHours: 24, labelEvery: 6, labelEveryUnit: .hour),
            // ZoomLevel(level: 48, name: LocalizedString("48h"), visibleHours: 48, labelEvery: 8, labelEveryUnit: .hour),
        ]
    }

    @State private var seriesWidth: CGFloat = 0
    @State private var cgmSeries: [ChartDatapoint] = []
    @State private var bgmSeries: [ChartDatapoint] = []

    @State private var cgmPointInfos: [Date: ChartDatapoint] = [:]
    @State private var bgmPointInfos: [Date: ChartDatapoint] = [:]

    @State private var selectedCGMPoint: ChartDatapoint? = nil
    @State private var selectedBGMPoint: ChartDatapoint? = nil

    private let calculationQueue = DispatchQueue(label: "libre-direct.chart-calculation", qos: .utility)

    private func shouldUpdate(newScenePhase: ScenePhase? = nil) -> Bool {
        let isRightView = store.state.selectedView == 1
        let isActiveView = (newScenePhase ?? scenePhase) == .active

        DirectLog.info("shouldUpdate \(isRightView && isActiveView) (\(isRightView) && \(isActiveView))")

        return isRightView && isActiveView
    }

    private func isSelectedZoomLevel(level: Int) -> Bool {
        if let zoomLevel = zoomLevel, zoomLevel.level == level {
            return true
        }

        return false
    }

    private func scrollToStart(scrollViewProxy: ScrollViewProxy) {
        scrollViewProxy.scrollTo(Config.chartID, anchor: .leading)
    }

    private func scrollToEnd(scrollViewProxy: ScrollViewProxy) {
        scrollViewProxy.scrollTo(Config.chartID, anchor: .trailing)
    }

    private func updateSeries(viewWidth: CGFloat, scrollViewProxy: ScrollViewProxy?) {
        DirectLog.info("updateSeries()")

        calculationQueue.async {
            let glucoseValues = self.glucoseValues.filter { value in
                value.isValidCGM() || value.isValidBGM()
            }

            if let firstTime = glucoseValues.first?.timestamp,
               let lastTime = glucoseValues.last?.timestamp,
               let startTime = Calendar.current.date(byAdding: .minute, value: -15, to: firstTime)?.timeIntervalSince1970,
               let endTime = Calendar.current.date(byAdding: .minute, value: 15, to: lastTime)?.timeIntervalSince1970,
               let zoomLevel = zoomLevel
            {
                let minuteWidth = (viewWidth / CGFloat(zoomLevel.visibleHours * 60))
                let chartMinutes = CGFloat((endTime - startTime) / 60)

                self.seriesWidth = CGFloat(minuteWidth * chartMinutes)
            }

            var cgmPointInfos: [Date: ChartDatapoint] = [:]
            let cgmSeries = populateValues(glucoseValues: glucoseValues.filter { $0.isSensorGlucose })
            cgmSeries.forEach { value in
                if cgmPointInfos[value.valueX] == nil {
                    cgmPointInfos[value.valueX] = value
                }
            }

            var bgmPointInfos: [Date: ChartDatapoint] = [:]
            let bgmSeries = populateValues(glucoseValues: glucoseValues.filter { $0.isBloodGlucose })
            bgmSeries.forEach { value in
                if bgmPointInfos[value.valueX] == nil {
                    bgmPointInfos[value.valueX] = value
                }
            }

            DispatchQueue.main.async {
                self.cgmSeries = cgmSeries
                self.cgmPointInfos = cgmPointInfos

                self.bgmSeries = bgmSeries
                self.bgmPointInfos = bgmPointInfos

                if let scrollProxy = scrollViewProxy {
                    self.scrollToEnd(scrollViewProxy: scrollProxy)
                }
            }
        }
    }

    private func populateValues(glucoseValues: [Glucose]) -> [ChartDatapoint] {
        glucoseValues.map { value in
            value.toDatapoint(glucoseUnit: glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh)
        }
        .compactMap { $0 }
    }
}

// MARK: - ZoomLevel

struct ZoomLevel {
    let level: Int
    let name: String
    let visibleHours: Int
    let labelEvery: Int
    let labelEveryUnit: Calendar.Component
}

// MARK: - ChartDatapoint

struct ChartDatapoint: Identifiable {
    let id: String
    let valueX: Date
    let valueY: Decimal
    let info: String
}

// MARK: Equatable

extension ChartDatapoint: Equatable {
    static func == (lhs: ChartDatapoint, rhs: ChartDatapoint) -> Bool {
        lhs.id == rhs.id
    }
}

extension Glucose {
    func isValidCGM() -> Bool {
        isSensorGlucose && glucoseValue != nil
    }

    func isValidBGM() -> Bool {
        isBloodGlucose && glucoseValue != nil
    }

    func toDatapointID(glucoseUnit: GlucoseUnit) -> String {
        "\(id.uuidString)-\(glucoseUnit.rawValue)"
    }

    func toDatapoint(glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int) -> ChartDatapoint? {
        guard let glucoseValue = glucoseValue else {
            return nil
        }

        if glucoseUnit == .mmolL {
            return ChartDatapoint(
                id: toDatapointID(glucoseUnit: glucoseUnit),
                valueX: timestamp,
                valueY: glucoseValue.asMmolL,
                info: glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true)
            )
        }

        return ChartDatapoint(
            id: toDatapointID(glucoseUnit: glucoseUnit),
            valueX: timestamp,
            valueY: glucoseValue.asMgdL,
            info: glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true)
        )
    }
}
