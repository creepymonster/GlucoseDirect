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

    var body: some View {
        Section(
            content: {
                VStack {
                    HStack {
                        Button(action: {
                            setSelectedDate(addDays: -1)
                        }, label: {
                            Image(systemName: "arrowshape.turn.up.backward")
                        }).opacity((store.state.selectedDate ?? Date()).startOfDay > store.state.minSelectedDate.startOfDay ? 0.5 : 0)

                        Spacer()

                        Group {
                            if let selectedDate = store.state.selectedDate {
                                Text(verbatim: selectedDate.toLocalDate())
                            } else {
                                Text("Last \(DirectConfig.lastChartHours.description) hours")
                            }
                        }.onTapGesture {
                            store.dispatch(.setSelectedDate(selectedDate: nil))
                        }

                        Spacer()

                        Button(action: {
                            setSelectedDate(addDays: +1)
                        }, label: {
                            Image(systemName: "arrowshape.turn.up.forward")
                        }).opacity(store.state.selectedDate == nil ? 0 : 0.5)
                    }
                    .buttonStyle(.plain)

                    ScrollViewReader { scrollViewProxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            ChartView
                                .frame(width: max(0, Config.screenWidth, seriesWidth), height: min(UIScreen.screenHeight, Config.chartHeight))
                                .onChange(of: store.state.sensorGlucoseValues) { _ in
                                    scrollToEnd(scrollViewProxy: scrollViewProxy)

                                }.onChange(of: store.state.bloodGlucoseValues) { _ in
                                    scrollToEnd(scrollViewProxy: scrollViewProxy)

                                }.onChange(of: store.state.chartZoomLevel) { _ in
                                    scrollToEnd(scrollViewProxy: scrollViewProxy, force: true)

                                }.onAppear {
                                    scrollToEnd(scrollViewProxy: scrollViewProxy)
                                }
                        }
                    }

                    ZoomLevelsView.disabled(store.state.selectedDate != nil)
                }
            },
            header: {
                Label("Chart", systemImage: "chart.xyaxis.line")
            }
        )
    }

    var ZoomLevelsView: some View {
        HStack {
            ForEach(Config.zoomLevels, id: \.level) { zoom in
                Button(
                    action: {
                        DirectNotifications.shared.hapticFeedback()
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

    var ChartView: some View {
        ZStack(alignment: .topLeading) {
            Chart {
                if store.state.glucoseUnit == .mgdL {
                    RuleMark(y: .value("Minimum High", 300))
                        .foregroundStyle(.clear)
                } else {
                    RuleMark(y: .value("Minimum High", 15))
                        .foregroundStyle(.clear)
                }

                RuleMark(y: .value("Lower limit", alarmLow))
                    .foregroundStyle(Color.ui.red)
                    .lineStyle(Config.ruleStyle)

                RuleMark(y: .value("Upper limit", alarmHigh))
                    .foregroundStyle(Color.ui.red)
                    .lineStyle(Config.ruleStyle)

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

                if let endMarker = endMarker, store.state.selectedDate == nil, store.state.chartZoomLevel != 24 {
                    RuleMark(
                        x: .value("", endMarker)
                    ).foregroundStyle(.clear)
                }
            }
            .chartPlotStyle { plotArea in
                plotArea.padding(.vertical)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: labelEveryUnit, count: labelEvery)) { value in
                    if let dateValue = value.as(Date.self) {
                        AxisGridLine(stroke: Config.axisStyle)
                        // AxisTick(stroke: Config.axisStyle)
                        AxisTick(length: 4, stroke: Config.tickStyle)
                        AxisValueLabel(dateValue.toLocalTime(onlyHour: onlyHour), anchor: .top)
                        // AxisValueLabel(anchor: .)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisGridLine(stroke: Config.axisStyle)
                    if let glucoseValue = value.as(Decimal.self), glucoseValue > 0 {
                        AxisTick(length: 4, stroke: Config.tickStyle)
                        AxisValueLabel()
                    }
                }
            }
            .id(Config.chartID)
            .onChange(of: store.state.glucoseUnit) { _ in
                if shouldRefresh {
                    updateSeriesMetadata()
                    updateSensorSeries()
                    updateBloodSeries()
                }

            }.onChange(of: store.state.sensorGlucoseValues) { _ in
                if shouldRefresh {
                    updateSeriesMetadata()
                    updateSensorSeries()
                }

            }.onChange(of: store.state.bloodGlucoseValues) { _ in
                if shouldRefresh {
                    updateSeriesMetadata()
                    updateBloodSeries()
                }

            }.onChange(of: store.state.chartZoomLevel) { _ in
                if shouldRefresh {
                    updateSeriesMetadata()
                    updateSensorSeries()
                    updateBloodSeries()
                }

            }.onChange(of: store.state.selectedDate) { _ in
                selectedSensorPoint = nil
                selectedBloodPoint = nil

            }.onAppear {
                updateSeriesMetadata()
                updateSensorSeries()
                updateBloodSeries()

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

    // MARK: Private

    private enum Config {
        static let chartID = "chart"
        static let symbolSize: CGFloat = 10
        static let selectionSize: CGFloat = 100
        static let spacerWidth: CGFloat = 50
        static let chartHeight: CGFloat = 340
        static let lineStyle: StrokeStyle = .init(lineWidth: 2.5, lineCap: .round)
        static let ruleStyle: StrokeStyle = .init(lineWidth: 1, dash: [2])
        static let gridStyle: StrokeStyle = .init(lineWidth: 1)
        static let dayStyle: StrokeStyle = .init(lineWidth: 1)
        static let axisStyle: StrokeStyle = .init(lineWidth: 0.5, dash: [2, 3])
        static let tickStyle: StrokeStyle = .init(lineWidth: 4)
        static let zoomLevels: [ZoomLevel] = [
            ZoomLevel(level: 1, name: LocalizedString("1h"), visibleHours: 1, labelEvery: 1, labelEveryUnit: .hour, onlyHour: false),
            ZoomLevel(level: 3, name: LocalizedString("3h"), visibleHours: 3, labelEvery: 1, labelEveryUnit: .hour, onlyHour: false),
            ZoomLevel(level: 6, name: LocalizedString("6h"), visibleHours: 6, labelEvery: 1, labelEveryUnit: .hour, onlyHour: true),
            ZoomLevel(level: 12, name: LocalizedString("12h"), visibleHours: 12, labelEvery: 2, labelEveryUnit: .hour, onlyHour: true),
            ZoomLevel(level: 24, name: LocalizedString("24h"), visibleHours: 24, labelEvery: 3, labelEveryUnit: .hour, onlyHour: true)
        ]

        static var screenWidth: CGFloat {
            UIScreen.screenWidth - 40
        }
    }

    @State private var seriesWidth: CGFloat = 0
    @State private var sensorGlucoseSeries: [ChartDatapoint] = []
    @State private var bloodGlucoseSeries: [ChartDatapoint] = []

    @State private var sensorPointInfos: [Date: ChartDatapoint] = [:]
    @State private var bloodPointInfos: [Date: ChartDatapoint] = [:]

    @State private var selectedSensorPoint: ChartDatapoint? = nil
    @State private var selectedBloodPoint: ChartDatapoint? = nil

    private let calculationQueue = DispatchQueue(label: "libre-direct.chart-calculation", qos: .utility)

    private var zoomLevel: ZoomLevel? {
        Config.zoomLevels.first(where: { $0.level == store.state.chartZoomLevel })
    }

    private var glucoseUnit: GlucoseUnit {
        store.state.glucoseUnit
    }

    private var labelEveryUnit: Calendar.Component {
        if let zoomLevel = zoomLevel {
            return zoomLevel.labelEveryUnit
        }

        return .hour
    }

    private var onlyHour: Bool {
        if let zoomLevel = zoomLevel {
            return zoomLevel.onlyHour
        }

        return true
    }

    private var labelEvery: Int {
        if let zoomLevel = zoomLevel {
            return zoomLevel.labelEvery
        }

        return 1
    }

    private var alarmLow: Decimal {
        if glucoseUnit == .mmolL {
            return store.state.alarmLow.asMmolL
        }

        return store.state.alarmLow.asMgdL
    }

    private var alarmHigh: Decimal {
        if glucoseUnit == .mmolL {
            return store.state.alarmHigh.asMmolL
        }

        return store.state.alarmHigh.asMgdL
    }

    private var startMarker: Date? {
        if let firstTimestamp = firstTimestamp {
            if let zoomLevel = zoomLevel, zoomLevel.level == 1 {
                return Calendar.current.date(byAdding: .minute, value: -15, to: firstTimestamp)!
            }

            return Calendar.current.date(byAdding: .hour, value: -1, to: firstTimestamp)!
        }

        return nil
    }

    private var endMarker: Date? {
        if let lastTimestamp = lastTimestamp {
            if let zoomLevel = zoomLevel, zoomLevel.level == 1 {
                return Calendar.current.date(byAdding: .minute, value: 15, to: lastTimestamp)!
            }

            return Calendar.current.date(byAdding: .hour, value: 1, to: lastTimestamp)!
        }

        return nil
    }

    private var shouldRefresh: Bool {
        store.state.appState == .active
    }

    private var firstTimestamp: Date? {
        let dates = [store.state.sensorGlucoseValues.first?.timestamp, store.state.bloodGlucoseValues.first?.timestamp]
            .compactMap { $0 }
            .sorted(by: { $0 < $1 })

        return dates.first
    }

    private var lastTimestamp: Date? {
        let dates = [store.state.sensorGlucoseValues.last?.timestamp, store.state.bloodGlucoseValues.last?.timestamp]
            .compactMap { $0 }
            .sorted(by: { $0 > $1 })

        return dates.first
    }

    private func setSelectedDate(addDays: Int) {
        store.dispatch(.setChartZoomLevel(level: 24))
        store.dispatch(.setSelectedDate(selectedDate: Calendar.current.date(byAdding: .day, value: +addDays, to: store.state.selectedDate ?? Date())))

        DirectNotifications.shared.hapticFeedback()
    }

    private func isSelectedZoomLevel(level: Int) -> Bool {
        if let zoomLevel = zoomLevel, zoomLevel.level == level {
            return true
        }

        return false
    }

    private func scrollToStart(scrollViewProxy: ScrollViewProxy, force: Bool = false) {
        scrollTo(scrollViewProxy: scrollViewProxy, force: force, anchor: .leading)
    }

    private func scrollToEnd(scrollViewProxy: ScrollViewProxy, force: Bool = false) {
        scrollTo(scrollViewProxy: scrollViewProxy, force: force, anchor: .trailing)
    }

    private func scrollTo(scrollViewProxy: ScrollViewProxy, force: Bool = false, anchor: UnitPoint) {
        if selectedSensorPoint == nil && selectedBloodPoint == nil || force {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                scrollViewProxy.scrollTo(Config.chartID, anchor: anchor)
            }

            if force {
                selectedSensorPoint = nil
                selectedBloodPoint = nil
            }
        }
    }

    private func updateSeriesMetadata() {
        DirectLog.info("updateSeriesMetadata()")

        calculationQueue.async {
            if let firstTimestamp = firstTimestamp,
               let lastTimestamp = lastTimestamp,
               let zoomLevel = zoomLevel
            {
                let minuteWidth = (Config.screenWidth / CGFloat(zoomLevel.visibleHours * 60))
                let chartMinutes = CGFloat((lastTimestamp.timeIntervalSince1970 - firstTimestamp.timeIntervalSince1970) / 60)
                let seriesWidth = CGFloat(minuteWidth * chartMinutes)

                if self.seriesWidth != seriesWidth {
                    DispatchQueue.main.async {
                        self.seriesWidth = seriesWidth
                    }
                }
            }
        }
    }

    private func updateSensorSeries() {
        DirectLog.info("updateSensorSeries()")

        calculationQueue.async {
            var sensorPointInfos: [Date: ChartDatapoint] = [:]
            let sensorGlucoseSeries = populateValues(glucoseValues: store.state.sensorGlucoseValues)
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
            let bloddGlucoseSeries = populateValues(glucoseValues: store.state.bloodGlucoseValues)
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

// MARK: - ChartDatapoint + Equatable

extension ChartDatapoint: Equatable {
    static func == (lhs: ChartDatapoint, rhs: ChartDatapoint) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ZoomLevel

private struct ZoomLevel {
    let level: Int
    let name: String
    let visibleHours: Int
    let labelEvery: Int
    let labelEveryUnit: Calendar.Component
    let onlyHour: Bool
}

// MARK: - ChartDatapoint

private struct ChartDatapoint: Identifiable {
    let id: String
    let valueX: Date
    let valueY: Decimal
    let info: String
}

private extension BloodGlucose {
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

private extension SensorGlucose {
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
