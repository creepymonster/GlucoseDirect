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
                                Text("\(DirectConfig.lastChartHours.description) hours")
                            }
                        }
                        .monospacedDigit()
                        .onTapGesture {
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

                                    }.onChange(of: store.state.insulinDeliveryValues) { _ in
                                        scrollToEnd(scrollViewProxy: scrollViewProxy)

                                    }.onChange(of: store.state.chartZoomLevel) { _ in
                                        scrollToEnd(scrollViewProxy: scrollViewProxy, force: true)

                                    }.onAppear {
                                        scrollToEnd(scrollViewProxy: scrollViewProxy)

                                    }.onTapGesture(count: 2) {
                                        showUnsmoothedValues = !showUnsmoothedValues
                                    }
                            }
                        }

                        if selectedSmoothSensorPoint != nil || selectedRawSensorPoint != nil || selectedBloodPoint != nil {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    if let selectedSensorPoint = selectedSmoothSensorPoint {
                                        VStack(alignment: .leading) {
                                            Text(selectedSensorPoint.time.toLocalDateTime())
                                            Text(selectedSensorPoint.info).bold()
                                        }
                                        .font(.footnote)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.ui.blue)
                                        .foregroundColor(Color.white)
                                        .cornerRadius(5)
                                    }

                                    if let selectedRawPoint = selectedRawSensorPoint, showUnsmoothedValues, store.state.showSmoothedGlucose {
                                        VStack(alignment: .leading) {
                                            Text(selectedRawPoint.time.toLocalDateTime())
                                            Text(selectedRawPoint.info).bold()
                                        }
                                        .font(.footnote)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.ui.orange)
                                        .foregroundColor(Color.white)
                                        .cornerRadius(5)
                                    }
                                }

                                if let selectedBloodPoint = selectedBloodPoint {
                                    HStack {
                                        Image(systemName: "drop.fill")

                                        VStack(alignment: .leading) {
                                            Text(selectedBloodPoint.time.toLocalDateTime())
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

                    ZoomLevelsView
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

            ForEach(smoothSensorGlucoseSeries) { value in
                LineMark(
                    x: .value("Time", value.time),
                    y: .value("Glucose", value.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Color.ui.blue)
                .lineStyle(Config.lineStyle)
            }

            ForEach(bloodGlucoseSeries) { value in
                PointMark(
                    x: .value("Time", value.time),
                    y: .value("Glucose", value.value)
                )
                .symbolSize(Config.symbolSize)
                .foregroundStyle(Color.ui.red)
            }

            ForEach(insulinSeries) { value in
                if value.type != .basal {
                    PointMark(
                        x: .value("Time", value.starts),
                        y: .value("Units", value.value.map(from: 0...20, to: convertToRequired(mgdLValue: 5)...Double(alarmLow)))
                    )
                    .symbolSize(value.value.map(from: 0...20, to: 20...100))
                    .annotation {
                        Text(value.value.asInsulin())
                            .foregroundStyle(Color.ui.orange)
                            .padding(.horizontal, 2.5)
                            .background(Config.backgroundColor.opacity(0.5))
                            .cornerRadius(2)
                            .bold()
                            .font(.caption)
                    }
                    .foregroundStyle(Color.ui.orange)
                } else {
                    RectangleMark(
                        xStart: .value("Starts", value.starts),
                        xEnd: .value("Ends", value.ends),
                        yStart: .value("Units", 0),
                        yEnd: .value("Units", value.value.map(from: 0...20, to: 0...Double(alarmLow)))
                    )
                    .opacity(0.25)
                    .annotation(position: .overlay, alignment: .bottom) {
                        Text(value.value.asInsulin())
                            .foregroundStyle(Color.ui.orange)
                            .padding(.horizontal, 2.5)
                            .background(Config.backgroundColor.opacity(0.5))
                            .cornerRadius(2)
                            .bold()
                            .font(.caption)
                    }
                    .foregroundStyle(Color.ui.orange)
                }
            }

            if showUnsmoothedValues, store.state.showSmoothedGlucose {
                if !rawSensorGlucoseSeries.isEmpty {
                    ForEach(rawSensorGlucoseSeries) { value in
                        LineMark(
                            x: .value("Time", value.time),
                            y: .value("Glucose", value.value),
                            series: .value("Series", "Raw")
                        )
                        .interpolationMethod(.monotone)
                        .opacity(0.5)
                        .foregroundStyle(Color.ui.orange)
                        .lineStyle(Config.rawLineStyle)
                    }
                }

                if let selectedPointInfo = selectedRawSensorPoint {
                    PointMark(
                        x: .value("Time", selectedPointInfo.time),
                        y: .value("Glucose", selectedPointInfo.value)
                    )
                    //.symbol(.square)
                    .opacity(0.75)
                    .symbolSize(Config.selectionSize)
                    .foregroundStyle(Color.ui.orange)
                }
            }

            if let selectedPointInfo = selectedSmoothSensorPoint {
                PointMark(
                    x: .value("Time", selectedPointInfo.time),
                    y: .value("Glucose", selectedPointInfo.value)
                )
                //.symbol(.square)
                .opacity(0.75)
                .symbolSize(Config.selectionSize)
                .foregroundStyle(Color.ui.blue)
            }

            if let selectedPointInfo = selectedBloodPoint {
                PointMark(
                    x: .value("Time", selectedPointInfo.time),
                    y: .value("Glucose", selectedPointInfo.value)
                )
                //.symbol(.square)
                .opacity(0.75)
                .symbolSize(Config.selectionSize)
                .foregroundStyle(Color.ui.red)
            }

            if let endMarker = endMarker {
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
            AxisMarks(position: .trailing, values: .stride(by: yAxisSteps)) { value in
                AxisGridLine(stroke: Config.axisStyle)

                if let glucoseValue = value.as(Double.self), glucoseValue > 0 {
                    AxisTick(length: 4, stroke: Config.tickStyle)
                        .foregroundStyle(Color.ui.gray)
                    AxisValueLabel()
                }
            }
        }
        .id(Config.chartID)
        .onChange(of: store.state.showSmoothedGlucose) { _ in
            if shouldRefresh {
                DirectLog.info("onChange: sensorGlucoseValues")

                updateSeriesMetadata()
                updateSensorSeries()
            }

        }.onChange(of: store.state.sensorGlucoseValues) { _ in
            if shouldRefresh {
                DirectLog.info("onChange: sensorGlucoseValues")

                updateSeriesMetadata()
                updateSensorSeries()
            }

        }.onChange(of: store.state.bloodGlucoseValues) { _ in
            if shouldRefresh {
                DirectLog.info("onChange: bloodGlucoseValues")

                updateSeriesMetadata()
                updateBloodSeries()
            }

        }.onChange(of: store.state.insulinDeliveryValues) { _ in
            if shouldRefresh {
                DirectLog.info("onChange: insulinDeliveryValues")

                updateSeriesMetadata()
                updateInsulinSeries()
            }

        }.onChange(of: store.state.chartZoomLevel) { _ in
            if shouldRefresh {
                DirectLog.info("onChange: chartZoomLevel")

                updateSeriesMetadata()
            }

        }.onChange(of: store.state.showSmoothedGlucose) { _ in
            showUnsmoothedValues = false

        }.onChange(of: store.state.selectedDate) { _ in
            selectedSmoothSensorPoint = nil
            selectedBloodPoint = nil

        }.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            if shouldRefresh {
                DirectLog.info("onChange: orientation")

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    updateSeriesMetadata()
                }
            }

        }.onAppear {
            DirectLog.info("onAppear")

            updateSeriesMetadata()
            updateSensorSeries()
            updateBloodSeries()
            updateInsulinSeries()

        }.chartOverlay { overlayProxy in
            GeometryReader { geometryProxy in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture()
                        .onChanged { value in
                            let currentX = value.location.x - geometryProxy[overlayProxy.plotAreaFrame].origin.x

                            if let currentDate: Date = overlayProxy.value(atX: currentX) {
                                let selectedSmoothSensorPoint = smoothSensorPointInfos[currentDate.toRounded(on: 1, .minute)]
                                let selectedRawSensorPoint = rawSensorPointInfos[currentDate.toRounded(on: 1, .minute)]
                                let selectedBloodPoint = bloodPointInfos[currentDate.toRounded(on: 1, .minute)]

                                if let selectedSmoothSensorPoint {
                                    self.selectedSmoothSensorPoint = selectedSmoothSensorPoint
                                }

                                self.selectedRawSensorPoint = selectedRawSensorPoint
                                self.selectedBloodPoint = selectedBloodPoint
                            }
                        }
                        .onEnded { _ in
                            selectedSmoothSensorPoint = nil
                            selectedRawSensorPoint = nil
                            selectedBloodPoint = nil
                        }
                    )
            }
        }
    }

    // MARK: Private

    private enum Config {
        static let backgroundColor = Color(uiColor: UIColor.systemBackground)
        static let chartID = "chart"
        static let cornerRadius: CGFloat = 20
        static let rangeCornerRadius: CGFloat = 2
        static let insulinSize: MarkDimension = 10
        static let symbolSize: CGFloat = 20
        static let selectionSize: CGFloat = 100
        static let spacerWidth: CGFloat = 50
        static let chartHeight: CGFloat = 340
        static let lineStyle: StrokeStyle = .init(lineWidth: 3, lineCap: .round)
        static let rawLineStyle: StrokeStyle = .init(lineWidth: 3, lineCap: .round)
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

    @State private var showUnsmoothedValues: Bool = false

    @State private var seriesWidth: CGFloat = 0
    @State private var smoothSensorGlucoseSeries: [GlucoseDatapoint] = []
    @State private var rawSensorGlucoseSeries: [GlucoseDatapoint] = []
    @State private var bloodGlucoseSeries: [GlucoseDatapoint] = []
    @State private var insulinSeries: [InsulinDatapoint] = []

    @State private var smoothSensorPointInfos: [Date: GlucoseDatapoint] = [:]
    @State private var rawSensorPointInfos: [Date: GlucoseDatapoint] = [:]
    @State private var bloodPointInfos: [Date: GlucoseDatapoint] = [:]

    @State private var selectedSmoothSensorPoint: GlucoseDatapoint? = nil
    @State private var selectedRawSensorPoint: GlucoseDatapoint? = nil
    @State private var selectedBloodPoint: GlucoseDatapoint? = nil

    private let calculationQueue = DispatchQueue(label: "libre-direct.chart-calculation", qos: .utility)

    private var screenHeight: CGFloat {
        UIScreen.screenHeight
    }

    private var screenWidth: CGFloat {
        UIScreen.screenWidth - 40
    }

    private var yAxisSteps: Double {
        if store.state.glucoseUnit == .mmolL {
            return 3
        }

        return 50
    }

    private var zoomLevel: ZoomLevel? {
        if let zoomLevel = Config.zoomLevels.first(where: { $0.level == store.state.chartZoomLevel }) {
            return zoomLevel
        }

        return Config.zoomLevels.first
    }

    private var labelEvery: Int {
        if let zoomLevel = zoomLevel {
            return zoomLevel.labelEvery
        }

        return 1
    }

    private var chartMinimum: Double {
        if store.state.glucoseUnit == .mmolL {
            return 18
        }

        return 300
    }

    private var alarmLow: Double {
        convertToRequired(mgdLValue: store.state.alarmLow)
    }

    private var alarmHigh: Double {
        convertToRequired(mgdLValue: store.state.alarmHigh)
    }

    private var startMarker: Date? {
        return firstTimestamp
    }

    private var endMarker: Date? {
        if let lastTimestamp = lastTimestamp, store.state.selectedDate == nil {
            if let zoomLevel = zoomLevel, zoomLevel.level == 1 {
                return Calendar.current.date(byAdding: .minute, value: 15, to: lastTimestamp)!
            }

            return Calendar.current.date(byAdding: .hour, value: 1, to: lastTimestamp)!
        }

        return lastTimestamp
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

    private func convertToRequired(mgdLValue: Int) -> Double {
        if store.state.glucoseUnit == .mmolL {
            return mgdLValue.toMmolL()
        }

        return mgdLValue.toDouble()
    }

    private func setSelectedDate(addDays: Int) {
        // store.dispatch(.setChartZoomLevel(level: 24))
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
        if selectedSmoothSensorPoint == nil || force {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                scrollViewProxy.scrollTo(Config.chartID, anchor: anchor)
            }

            if force {
                selectedSmoothSensorPoint = nil
                selectedRawSensorPoint = nil
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
            var smoothSensorPointInfos: [Date: GlucoseDatapoint] = [:]
            var rawSensorPointInfos: [Date: GlucoseDatapoint] = [:]

            let smoothSensorGlucoseSeries = DirectConfig.showSmoothedGlucose && store.state.showSmoothedGlucose
                ? populateSmoothValues(glucoseValues: store.state.sensorGlucoseValues)
                : populateValues(glucoseValues: store.state.sensorGlucoseValues)
            smoothSensorGlucoseSeries.forEach { value in
                if smoothSensorPointInfos[value.time] == nil {
                    smoothSensorPointInfos[value.time] = value
                }
            }

            let rawSensorGlucoseSeries = store.state.showSmoothedGlucose
                ? populateValues(glucoseValues: store.state.sensorGlucoseValues.filter {
                    $0.timestamp < store.state.smoothThreshold
                })
                : []
            rawSensorGlucoseSeries.forEach { value in
                if rawSensorPointInfos[value.time] == nil {
                    rawSensorPointInfos[value.time] = value
                }
            }

            DispatchQueue.main.async {
                self.smoothSensorGlucoseSeries = smoothSensorGlucoseSeries
                self.smoothSensorPointInfos = smoothSensorPointInfos

                self.rawSensorGlucoseSeries = rawSensorGlucoseSeries
                self.rawSensorPointInfos = rawSensorPointInfos
            }
        }
    }

    private func updateBloodSeries() {
        DirectLog.info("updateBloodSeries()")

        calculationQueue.async {
            var bloodPointInfos: [Date: GlucoseDatapoint] = [:]
            let bloodGlucoseSeries = populateValues(glucoseValues: store.state.bloodGlucoseValues)
            bloodGlucoseSeries.forEach { value in
                if bloodPointInfos[value.time] == nil {
                    bloodPointInfos[value.time] = value
                }
            }

            DispatchQueue.main.async {
                self.bloodGlucoseSeries = bloodGlucoseSeries
                self.bloodPointInfos = bloodPointInfos
            }
        }
    }

    private func updateInsulinSeries() {
        DirectLog.info("updateInsulinSeries()")

        calculationQueue.async {
            let insulinSeries = populateValues(glucoseValues: store.state.insulinDeliveryValues)

            DispatchQueue.main.async {
                self.insulinSeries = insulinSeries
            }
        }
    }

    private func populateValues(glucoseValues: [InsulinDelivery]) -> [InsulinDatapoint] {
        glucoseValues.map { value in
            value.toDatapoint(minDate: startMarker ?? Date(), maxDate: endMarker ?? Date())
        }
        .compactMap { $0 }
    }

    private func populateValues(glucoseValues: [BloodGlucose]) -> [GlucoseDatapoint] {
        glucoseValues.map { value in
            value.toDatapoint(glucoseUnit: store.state.glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh)
        }
        .compactMap { $0 }
    }

    private func populateValues(glucoseValues: [SensorGlucose]) -> [GlucoseDatapoint] {
        return glucoseValues.map { value in
            value.toDatapoint(glucoseUnit: store.state.glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh)
        }.compactMap { $0 }
    }

    private func populateSmoothValues(glucoseValues: [SensorGlucose]) -> [GlucoseDatapoint] {
        return glucoseValues.map { value in
            if value.timestamp < store.state.smoothThreshold {
                return value.toSmoothDatapoint(glucoseUnit: store.state.glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh)
            }

            return value.toDatapoint(glucoseUnit: store.state.glucoseUnit, alarmLow: store.state.alarmLow, alarmHigh: store.state.alarmHigh)
        }.compactMap { $0 }
    }
}

// MARK: - ChartDatapoint + Equatable

extension GlucoseDatapoint: Equatable {
    static func == (lhs: GlucoseDatapoint, rhs: GlucoseDatapoint) -> Bool {
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

private struct GlucoseDatapoint: Identifiable {
    let id: String
    let time: Date
    let value: Double
    let info: String
}

private struct InsulinDatapoint: Identifiable {
    let id: String
    let starts: Date
    let ends: Date
    let value: Double
    let type: InsulinType
    let info: String
}

private extension InsulinDelivery {
    func toDatapoint(minDate: Date, maxDate: Date) -> InsulinDatapoint {
        return InsulinDatapoint(
            id: id.uuidString,
            starts: max(minDate, starts),
            ends: min(maxDate, ends),
            value: units,
            type: type,
            info: type.localizedDescription
        )
    }
}

private extension BloodGlucose {
    func toDatapointID(glucoseUnit: GlucoseUnit) -> String {
        "\(id.uuidString)-\(glucoseUnit.rawValue)"
    }

    func toDatapoint(glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int) -> GlucoseDatapoint {
        if glucoseUnit == .mmolL {
            return GlucoseDatapoint(
                id: toDatapointID(glucoseUnit: glucoseUnit),
                time: timestamp,
                value: glucoseValue.toMmolL(),
                info: glucoseValue.asGlucose(glucoseUnit: glucoseUnit, withUnit: true)
            )
        }

        return GlucoseDatapoint(
            id: toDatapointID(glucoseUnit: glucoseUnit),
            time: timestamp,
            value: glucoseValue.toDouble(),
            info: glucoseValue.asGlucose(glucoseUnit: glucoseUnit, withUnit: true)
        )
    }
}

private extension SensorGlucose {
    func toDatapointID(glucoseUnit: GlucoseUnit) -> String {
        "\(id.uuidString)-\(glucoseUnit.rawValue)"
    }

    func toRawDatapoint(glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int, shiftY: Int = 0) -> GlucoseDatapoint {
        if glucoseUnit == .mmolL {
            return GlucoseDatapoint(
                id: toDatapointID(glucoseUnit: glucoseUnit),
                time: timestamp,
                value: rawGlucoseValue.toMmolL() + shiftY.toMmolL(),
                info: rawGlucoseValue.asGlucose(glucoseUnit: glucoseUnit, withUnit: true)
            )
        }

        return GlucoseDatapoint(
            id: toDatapointID(glucoseUnit: glucoseUnit),
            time: timestamp,
            value: rawGlucoseValue.toDouble() + shiftY.toDouble(),
            info: rawGlucoseValue.asGlucose(glucoseUnit: glucoseUnit, withUnit: true)
        )
    }

    func toSmoothDatapoint(glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int, shiftY: Int = 0) -> GlucoseDatapoint {
        let glucose = (smoothGlucoseValue ?? Double(glucoseValue))
        let info = glucose.toInteger()?.asGlucose(glucoseUnit: glucoseUnit, withUnit: true) ?? ""

        if glucoseUnit == .mmolL {
            return GlucoseDatapoint(
                id: toDatapointID(glucoseUnit: glucoseUnit),
                time: timestamp,
                value: glucose.toMmolL() + shiftY.toMmolL(),
                info: info
            )
        }

        return GlucoseDatapoint(
            id: toDatapointID(glucoseUnit: glucoseUnit),
            time: timestamp,
            value: glucose + shiftY.toDouble(),
            info: info
        )
    }

    func toDatapoint(glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int, shiftY: Int = 0) -> GlucoseDatapoint {
        var info: String

        if let minuteChange = minuteChange {
            info = "\(glucoseValue.asGlucose(glucoseUnit: glucoseUnit, withUnit: true)) \(minuteChange.asMinuteChange(glucoseUnit: glucoseUnit))"
        } else {
            info = glucoseValue.asGlucose(glucoseUnit: glucoseUnit, withUnit: true)
        }

        if glucoseUnit == .mmolL {
            return GlucoseDatapoint(
                id: toDatapointID(glucoseUnit: glucoseUnit),
                time: timestamp,
                value: glucoseValue.toMmolL() + shiftY.toMmolL(),
                info: info
            )
        }

        return GlucoseDatapoint(
            id: toDatapointID(glucoseUnit: glucoseUnit),
            time: timestamp,
            value: glucoseValue.toDouble() + shiftY.toDouble(),
            info: info
        )
    }
}
