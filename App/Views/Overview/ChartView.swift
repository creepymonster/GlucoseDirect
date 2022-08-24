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

    var bloodGlucoseValues: [BloodGlucose] {
        store.state.bloodGlucoseHistory + store.state.bloodGlucoseValues
    }

    var sensorGlucoseValues: [SensorGlucose] {
        store.state.sensorGlucoseHistory + store.state.sensorGlucoseValues
    }

    var endMarker: Date {
        if let zoomLevel = zoomLevel, zoomLevel.level == 1 {
            return Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        }

        return Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    }

    var ChartView: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geometryProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollViewProxy in
                        Chart {
                            RuleMark(y: .value("Lower limit", alarmLow))
                                .foregroundStyle(Color.ui.red)
                                .lineStyle(Config.ruleStyle)

                            RuleMark(y: .value("Upper limit", alarmHigh))
                                .foregroundStyle(Color.ui.red)
                                .lineStyle(Config.ruleStyle)

                            ForEach(seriesDays, id: \.self) { day in
                                RuleMark(
                                    x: .value("", day)
                                )
                                .foregroundStyle(Color.ui.gray)
                                .lineStyle(Config.dayStyle)
                            }

                            ForEach(sensorGlucoseSeries) { value in
                                LineMark(
                                    x: .value("Time", value.valueX),
                                    y: .value("Glucose", value.valueY)
                                )
                                .foregroundStyle(Color.ui.blue)
                                .lineStyle(Config.lineStyle)
                            }

                            ForEach(bloodGlucoseSeries) { value in
                                PointMark(
                                    x: .value("Time", value.valueX),
                                    y: .value("Glucose", value.valueY)
                                )
                                .symbolSize(Config.symbolSize)
                                .foregroundStyle(Color.ui.red)
                            }

                            if let selectedPointInfo = selectedSensorPoint {
                                PointMark(
                                    x: .value("Time", selectedPointInfo.valueX),
                                    y: .value("Glucose", selectedPointInfo.valueY)
                                )
                                .symbolSize(Config.selectionSize)
                                .opacity(0.5)
                                .foregroundStyle(Color.primary)
                            }

                            if let selectedPointInfo = selectedBloodPoint {
                                PointMark(
                                    x: .value("Time", selectedPointInfo.valueX),
                                    y: .value("Glucose", selectedPointInfo.valueY)
                                )
                                .symbolSize(Config.selectionSize)
                                .opacity(0.5)
                                .foregroundStyle(Color.primary)
                            }

                            RuleMark(
                                x: .value("", endMarker)
                            ).foregroundStyle(.clear)
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
                        .onChange(of: store.state.glucoseUnit) { _ in
                            if shouldRefresh {
                                DirectLog.info("onChangeOfGlucoseUnit()")
                                updateSeriesMetadata(viewWidth: geometryProxy.size.width)
                                updateSensorSeries()
                                updateBloodSeries()
                            }

                        }.onChange(of: [store.state.sensorGlucoseValues, store.state.sensorGlucoseHistory]) { _ in
                            if shouldRefresh {
                                DirectLog.info("onChangeOfSensorGlucoseValues()")
                                updateSeriesMetadata(viewWidth: geometryProxy.size.width)
                                updateSensorSeries()
                            }

                        }.onChange(of: [store.state.bloodGlucoseValues, store.state.bloodGlucoseHistory]) { _ in
                            if shouldRefresh {
                                DirectLog.info("onChangeOfBloodGlucoseValues()")
                                updateSeriesMetadata(viewWidth: geometryProxy.size.width)
                                updateBloodSeries()
                            }

                        }.onChange(of: store.state.chartZoomLevel) { _ in
                            if shouldRefresh {
                                DirectLog.info("onChangeOfChartZoomLevel()")
                                updateSeriesMetadata(viewWidth: geometryProxy.size.width)
                                updateSensorSeries()
                                updateBloodSeries()
                            }

                        }.onChange(of: sensorGlucoseSeries) { _ in
                            scrollToEnd(scrollViewProxy: scrollViewProxy)

                        }.onChange(of: bloodGlucoseSeries) { _ in
                            scrollToEnd(scrollViewProxy: scrollViewProxy)

                        }.chartOverlay { overlayProxy in
                            GeometryReader { geometryProxy in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .gesture(DragGesture()
                                        .onChanged { value in
                                            let currentX = value.location.x - geometryProxy[overlayProxy.plotAreaFrame].origin.x

                                            if let currentDate: Date = overlayProxy.value(atX: currentX) {
                                                let selectedSensorPoint = sensorPointInfos[currentDate.toRounded(on: 1, .minute)]
                                                let selectedBloodPoint = bloodPointInfos[currentDate.toRounded(on: 1, .minute)]

                                                if let selectedSensorPoint {
                                                    self.selectedSensorPoint = selectedSensorPoint
                                                }

                                                self.selectedBloodPoint = selectedBloodPoint
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedSensorPoint = nil
                                            selectedBloodPoint = nil
                                        }
                                    )
                            }
                        }
                    }
                }
            }

            if selectedSensorPoint != nil || selectedBloodPoint != nil {
                HStack {
                    if let selectedSensorPoint = selectedSensorPoint {
                        VStack(alignment: .leading) {
                            Text(selectedSensorPoint.valueX.toLocalDateTime())
                            Text(selectedSensorPoint.info).bold()
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

                    if let selectedBloodPoint = selectedBloodPoint {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(Color.white)

                            VStack(alignment: .leading) {
                                Text(selectedBloodPoint.valueX.toLocalDateTime())
                                Text(selectedBloodPoint.info).bold()
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
                        DirectNotifications.shared.hapticNotification()
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
        static let symbolSize: CGFloat = 10
        static let selectionSize: CGFloat = 100
        static let spacerWidth: CGFloat = 50
        static let lineStyle: StrokeStyle = .init(lineWidth: 2.5, lineCap: .round)
        static let ruleStyle: StrokeStyle = .init(lineWidth: 1, dash: [2])
        static let gridStyle: StrokeStyle = .init(lineWidth: 1)
        static let dayStyle: StrokeStyle = .init(lineWidth: 1)

        static let zoomLevels: [ZoomLevel] = [
            ZoomLevel(level: 1, name: LocalizedString("1h"), visibleHours: 1, labelEvery: 30, labelEveryUnit: .minute),
            ZoomLevel(level: 3, name: LocalizedString("3h"), visibleHours: 3, labelEvery: 1, labelEveryUnit: .hour),
            ZoomLevel(level: 6, name: LocalizedString("6h"), visibleHours: 6, labelEvery: 2, labelEveryUnit: .hour),
            ZoomLevel(level: 12, name: LocalizedString("12h"), visibleHours: 12, labelEvery: 3, labelEveryUnit: .hour),
            ZoomLevel(level: 24, name: LocalizedString("24h"), visibleHours: 24, labelEvery: 6, labelEveryUnit: .hour)
        ]
    }

    @State private var seriesDays: [Date] = []
    @State private var seriesWidth: CGFloat = 0
    @State private var sensorGlucoseSeries: [ChartDatapoint] = []
    @State private var bloodGlucoseSeries: [ChartDatapoint] = []

    @State private var sensorPointInfos: [Date: ChartDatapoint] = [:]
    @State private var bloodPointInfos: [Date: ChartDatapoint] = [:]

    @State private var selectedSensorPoint: ChartDatapoint? = nil
    @State private var selectedBloodPoint: ChartDatapoint? = nil

    private let calculationQueue = DispatchQueue(label: "libre-direct.chart-calculation", qos: .utility)
    private let debouncer = Debouncer(delay: 0.5)

    private var shouldRefresh: Bool {
        store.state.appState == .active
    }

    private var firstTimestamp: Date? {
        let dates = [sensorGlucoseValues.first?.timestamp, bloodGlucoseValues.first?.timestamp]
            .compactMap { $0 }
            .sorted(by: { $0 < $1 })

        return dates.first
    }

    private var lastTimestamp: Date? {
        let dates = [sensorGlucoseValues.last?.timestamp, bloodGlucoseValues.last?.timestamp]
            .compactMap { $0 }
            .sorted(by: { $0 > $1 })

        return dates.first
    }

    private func isSelectedZoomLevel(level: Int) -> Bool {
        if let zoomLevel = zoomLevel, zoomLevel.level == level {
            return true
        }

        return false
    }

    private func scrollToStart(scrollViewProxy: ScrollViewProxy) {
        if selectedSensorPoint == nil, selectedBloodPoint == nil {
            DirectLog.info("scrollToStart()")
            scrollViewProxy.scrollTo(Config.chartID, anchor: .leading)
        }
    }

    private func scrollToEnd(scrollViewProxy: ScrollViewProxy) {
        if selectedSensorPoint == nil, selectedBloodPoint == nil {
            DirectLog.info("scrollToEnd()")
            scrollViewProxy.scrollTo(Config.chartID, anchor: .trailing)
        }
    }

    private func updateSeriesMetadata(viewWidth: CGFloat) {
        DirectLog.info("updateSeriesMetadata()")

        calculationQueue.async {
            if let firstTime = firstTimestamp,
               let lastTime = lastTimestamp,
               let startTime = Calendar.current.date(byAdding: .minute, value: -15, to: firstTime)?.timeIntervalSince1970,
               let endTime = Calendar.current.date(byAdding: .minute, value: 15, to: lastTime)?.timeIntervalSince1970,
               let zoomLevel = zoomLevel
            {
                let minuteWidth = (viewWidth / CGFloat(zoomLevel.visibleHours * 60))
                let chartMinutes = CGFloat((endTime - startTime) / 60)
                let seriesWidth = CGFloat(minuteWidth * chartMinutes)

                let seriesDays = Date.valuesBetween(from: firstTime, to: lastTime, component: .day, step: 1)

                if self.seriesWidth != seriesWidth {
                    DispatchQueue.main.async {
                        self.seriesWidth = seriesWidth
                        self.seriesDays = seriesDays
                    }
                }
            }
        }
    }

    private func updateSensorSeries() {
        DirectLog.info("updateSensorSeries()")

        calculationQueue.async {
            var sensorPointInfos: [Date: ChartDatapoint] = [:]
            let sensorGlucoseSeries = populateValues(glucoseValues: sensorGlucoseValues)
            sensorGlucoseSeries.forEach { value in
                if sensorPointInfos[value.valueX] == nil {
                    sensorPointInfos[value.valueX] = value
                }
            }

            DispatchQueue.main.async {
                self.sensorGlucoseSeries = sensorGlucoseSeries
                self.sensorPointInfos = sensorPointInfos
            }
        }
    }

    private func updateBloodSeries() {
        DirectLog.info("updateBloodSeries()")

        calculationQueue.async {
            var bloodPointInfos: [Date: ChartDatapoint] = [:]
            let bloddGlucoseSeries = populateValues(glucoseValues: bloodGlucoseValues)
            bloddGlucoseSeries.forEach { value in
                if bloodPointInfos[value.valueX] == nil {
                    bloodPointInfos[value.valueX] = value
                }
            }

            DispatchQueue.main.async {
                self.bloodGlucoseSeries = bloddGlucoseSeries
                self.bloodPointInfos = bloodPointInfos
            }
        }
    }

    private func populateValues(glucoseValues: [BloodGlucose]) -> [ChartDatapoint] {
        glucoseValues.map { value in
            value.toDatapoint(glucoseUnit: glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh)
        }
        .compactMap { $0 }
    }

    private func populateValues(glucoseValues: [SensorGlucose]) -> [ChartDatapoint] {
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

extension BloodGlucose {
    func toDatapointID(glucoseUnit: GlucoseUnit) -> String {
        "\(id.uuidString)-\(glucoseUnit.rawValue)"
    }

    func toDatapoint(glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int) -> ChartDatapoint {
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

extension SensorGlucose {
    func toDatapointID(glucoseUnit: GlucoseUnit) -> String {
        "\(id.uuidString)-\(glucoseUnit.rawValue)"
    }

    func toDatapoint(glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int) -> ChartDatapoint {
        var info: String

        if let minuteChange = minuteChange {
            info = "\(glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true)) \(minuteChange.asMinuteChange(glucoseUnit: glucoseUnit))"
        } else {
            info = glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true)
        }

        if glucoseUnit == .mmolL {
            return ChartDatapoint(
                id: toDatapointID(glucoseUnit: glucoseUnit),
                valueX: timestamp,
                valueY: glucoseValue.asMmolL,
                info: info
            )
        }

        return ChartDatapoint(
            id: toDatapointID(glucoseUnit: glucoseUnit),
            valueX: timestamp,
            valueY: glucoseValue.asMgdL,
            info: info
        )
    }
}

// MARK: - Debouncer

class Debouncer {
    // MARK: Lifecycle

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    // MARK: Internal

    func run(action: @escaping () -> Void) {
        workItem?.cancel()
        let workItem = DispatchWorkItem(block: action)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        self.workItem = workItem
    }

    func cancel() {
        workItem?.cancel()
    }

    // MARK: Private

    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
}
