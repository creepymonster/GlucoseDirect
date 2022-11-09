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

                    ZStack(alignment: .topLeading) {
                        ScrollViewReader { scrollViewProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                ChartView
                                    .frame(width: max(0, screenWidth, seriesWidth), height: min(screenHeight, Config.chartHeight))
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

                        if selectedSensorPoint != nil || selectedRawPoint != nil || selectedBloodPoint != nil {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    if let selectedSensorPoint = selectedSensorPoint {
                                        VStack(alignment: .leading) {
                                            Text(selectedSensorPoint.valueX.toLocalDateTime())
                                            Text(selectedSensorPoint.info).bold()
                                        }
                                        .font(.footnote)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.ui.blue)
                                        .foregroundColor(Color.white)
                                        .cornerRadius(5)
                                    }

                                    if let selectedRawPoint = selectedRawPoint {
                                        VStack(alignment: .leading) {
                                            Text(selectedRawPoint.valueX.toLocalDateTime())
                                            Text(selectedRawPoint.info).bold()
                                        }
                                        .font(.footnote)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.ui.yellow)
                                        .foregroundColor(Color.white)
                                        .cornerRadius(5)
                                    }
                                }

                                if let selectedBloodPoint = selectedBloodPoint {
                                    HStack {
                                        Image(systemName: "drop.fill")

                                        VStack(alignment: .leading) {
                                            Text(selectedBloodPoint.valueX.toLocalDateTime())
                                            Text(selectedBloodPoint.info).bold()
                                        }
                                    }
                                    .font(.footnote)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.ui.red)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(5)
                                }
                            }.opacity(0.75)
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
                if zoom != Config.zoomLevels.first {
                    Spacer()
                }

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
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
    }

    var ChartView: some View {
        Chart {
            RuleMark(y: .value("Minimum High", chartMinimum))
                .foregroundStyle(.clear)

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
                .interpolationMethod(.monotone)
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

            if !rawGlucoseSeries.isEmpty {
                ForEach(rawGlucoseSeries) { value in
                    LineMark(
                        x: .value("Time", value.valueX),
                        y: .value("Glucose", value.valueY),
                        series: .value("Series", "Raw")
                    )
                    .interpolationMethod(.monotone)
                    .opacity(0.5)
                    .foregroundStyle(Color.ui.yellow)
                    .lineStyle(Config.rawLineStyle)
                }
            }

            if let selectedPointInfo = selectedRawPoint {
                PointMark(
                    x: .value("Time", selectedPointInfo.valueX),
                    y: .value("Glucose", selectedPointInfo.valueY)
                )
                .symbol(.square)
                .opacity(0.75)
                .symbolSize(Config.selectionSize)
                .foregroundStyle(Color.ui.yellow)
            }

            if let selectedPointInfo = selectedSensorPoint {
                PointMark(
                    x: .value("Time", selectedPointInfo.valueX),
                    y: .value("Glucose", selectedPointInfo.valueY)
                )
                .symbol(.square)
                .opacity(0.75)
                .symbolSize(Config.selectionSize)
                .foregroundStyle(Color.ui.blue)
            }

            if let selectedPointInfo = selectedBloodPoint {
                PointMark(
                    x: .value("Time", selectedPointInfo.valueX),
                    y: .value("Glucose", selectedPointInfo.valueY)
                )
                .symbol(.square)
                .opacity(0.75)
                .symbolSize(Config.selectionSize)
                .foregroundStyle(Color.ui.red)
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
            AxisMarks(values: .stride(by: .hour, count: labelEvery)) { _ in
                AxisGridLine(stroke: Config.axisStyle)
                AxisTick(length: 4, stroke: Config.tickStyle)
                    .foregroundStyle(Color.ui.gray)
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .narrow)), anchor: .top)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine(stroke: Config.axisStyle)

                if let glucoseValue = value.as(Decimal.self), glucoseValue > 0 {
                    AxisTick(length: 4, stroke: Config.tickStyle)
                        .foregroundStyle(Color.ui.gray)
                    AxisValueLabel()
                }
            }
        }
        .id(Config.chartID)
        .onChange(of: store.state.glucoseUnit) { _ in
            if shouldRefresh {
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
            }

        }.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            if shouldRefresh {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    updateSeriesMetadata()
                }
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
                                let selectedRawPoint = rawPointInfos[currentDate.toRounded(on: 1, .minute)]
                                let selectedBloodPoint = bloodPointInfos[currentDate.toRounded(on: 1, .minute)]

                                if let selectedSensorPoint {
                                    self.selectedSensorPoint = selectedSensorPoint
                                }

                                if let selectedRawPoint {
                                    self.selectedRawPoint = selectedRawPoint
                                }

                                self.selectedBloodPoint = selectedBloodPoint
                            }
                        }
                        .onEnded { _ in
                            selectedSensorPoint = nil
                            selectedRawPoint = nil
                            selectedBloodPoint = nil
                        }
                    )
            }
        }
    }

    // MARK: Private

    private enum Config {
        static let chartID = "chart"
        static let symbolSize: CGFloat = 10
        static let selectionSize: CGFloat = 75
        static let spacerWidth: CGFloat = 50
        static let chartHeight: CGFloat = 340
        static let lineStyle: StrokeStyle = .init(lineWidth: 2, lineCap: .round)
        static let rawLineStyle: StrokeStyle = .init(lineWidth: 2, lineCap: .round)
        static let ruleStyle: StrokeStyle = .init(lineWidth: 1, dash: [2])
        static let gridStyle: StrokeStyle = .init(lineWidth: 1)
        static let dayStyle: StrokeStyle = .init(lineWidth: 1)
        static let axisStyle: StrokeStyle = .init(lineWidth: 0.5, dash: [2, 3])
        static let tickStyle: StrokeStyle = .init(lineWidth: 4)
        static let zoomLevels: [ZoomLevel] = [
            ZoomLevel(level: 3, name: LocalizedString("3h"), visibleHours: 3, labelEvery: 1),
            ZoomLevel(level: 6, name: LocalizedString("6h"), visibleHours: 6, labelEvery: 2),
            ZoomLevel(level: 12, name: LocalizedString("12h"), visibleHours: 12, labelEvery: 3),
            ZoomLevel(level: 24, name: LocalizedString("24h"), visibleHours: 24, labelEvery: 4)
        ]
    }

    @State private var seriesWidth: CGFloat = 0
    @State private var sensorGlucoseSeries: [ChartDatapoint] = []
    @State private var rawGlucoseSeries: [ChartDatapoint] = []
    @State private var bloodGlucoseSeries: [ChartDatapoint] = []

    @State private var sensorPointInfos: [Date: ChartDatapoint] = [:]
    @State private var rawPointInfos: [Date: ChartDatapoint] = [:]
    @State private var bloodPointInfos: [Date: ChartDatapoint] = [:]

    @State private var selectedSensorPoint: ChartDatapoint? = nil
    @State private var selectedRawPoint: ChartDatapoint? = nil
    @State private var selectedBloodPoint: ChartDatapoint? = nil

    private let calculationQueue = DispatchQueue(label: "libre-direct.chart-calculation", qos: .utility)

    private var screenHeight: CGFloat {
        UIScreen.screenHeight
    }

    private var screenWidth: CGFloat {
        UIScreen.screenWidth - 40
    }

    private var zoomLevel: ZoomLevel? {
        if let zoomLevel = Config.zoomLevels.first(where: { $0.level == store.state.chartZoomLevel }) {
            return zoomLevel
        }

        return Config.zoomLevels.first
    }

    private var glucoseUnit: GlucoseUnit {
        store.state.glucoseUnit
    }

    private var labelEvery: Int {
        if let zoomLevel = zoomLevel {
            return zoomLevel.labelEvery
        }

        return 1
    }

    private var chartMinimum: Decimal {
        if glucoseUnit == .mmolL {
            return 15
        }

        return 300
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
        if selectedSensorPoint == nil || force {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                scrollViewProxy.scrollTo(Config.chartID, anchor: anchor)
            }

            if force {
                selectedSensorPoint = nil
                selectedRawPoint = nil
                selectedBloodPoint = nil
            }
        }
    }

    private func updateSeriesMetadata() {
        DirectLog.info("updateSeriesMetadata()")

        if let firstTimestamp = firstTimestamp,
           let lastTimestamp = lastTimestamp,
           let zoomLevel = zoomLevel
        {
            let minuteWidth = (screenWidth / CGFloat(zoomLevel.visibleHours * 60))
            let chartMinutes = CGFloat((lastTimestamp.timeIntervalSince1970 - firstTimestamp.timeIntervalSince1970) / 60)
            let seriesWidth = CGFloat(minuteWidth * chartMinutes)

            if self.seriesWidth != seriesWidth {
                self.seriesWidth = seriesWidth
            }
        }
    }

    private func updateSensorSeries() {
        DirectLog.info("updateSensorSeries()")

        calculationQueue.async {
            var sensorPointInfos: [Date: ChartDatapoint] = [:]
            var rawPointInfos: [Date: ChartDatapoint] = [:]

            let sensorGlucoseSeries = populateValues(glucoseValues: store.state.sensorGlucoseValues)
            sensorGlucoseSeries.forEach { value in
                if sensorPointInfos[value.valueX] == nil {
                    sensorPointInfos[value.valueX] = value
                }
            }

            let rawGlucoseSeries = store.state.smoothSensorGlucoseValues
                ? populateRawValues(glucoseValues: store.state.sensorGlucoseValues)
                : populateRawValues(glucoseValues: [])

            rawGlucoseSeries.forEach { value in
                if rawPointInfos[value.valueX] == nil {
                    rawPointInfos[value.valueX] = value
                }
            }

            DispatchQueue.main.async {
                self.sensorGlucoseSeries = sensorGlucoseSeries
                self.rawGlucoseSeries = rawGlucoseSeries

                self.sensorPointInfos = sensorPointInfos
                self.rawPointInfos = rawPointInfos
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

    private func populateRawValues(glucoseValues: [SensorGlucose]) -> [ChartDatapoint] {
        glucoseValues.map { value in
            value.toRawDatapoint(glucoseUnit: glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh)
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
}

// MARK: Equatable

extension ZoomLevel: Equatable {
    static func == (lhs: ZoomLevel, rhs: ZoomLevel) -> Bool {
        lhs.level == rhs.level
    }
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

    func toRawDatapoint(glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int, shiftY: Int = 0) -> ChartDatapoint {
        if glucoseUnit == .mmolL {
            return ChartDatapoint(
                id: toDatapointID(glucoseUnit: glucoseUnit),
                valueX: timestamp,
                valueY: rawGlucoseValue.asMmolL + shiftY.asMmolL,
                info: rawGlucoseValue.asGlucose(unit: glucoseUnit, withUnit: true)
            )
        }

        return ChartDatapoint(
            id: toDatapointID(glucoseUnit: glucoseUnit),
            valueX: timestamp,
            valueY: rawGlucoseValue.asMgdL + shiftY.asMgdL,
            info: rawGlucoseValue.asGlucose(unit: glucoseUnit, withUnit: true)
        )
    }

    func toDatapoint(glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int, shiftY: Int = 0) -> ChartDatapoint {
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
                valueY: glucoseValue.asMmolL + shiftY.asMmolL,
                info: info
            )
        }

        return ChartDatapoint(
            id: toDatapointID(glucoseUnit: glucoseUnit),
            valueX: timestamp,
            valueY: glucoseValue.asMgdL + shiftY.asMgdL,
            info: info
        )
    }
}
