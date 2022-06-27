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

    @EnvironmentObject var store: AppStore

    var zoomLevel: ZoomLevel? {
        Config.zoomLevels.first(where: { $0.level == store.state.chartZoomLevel })
    }

    var glucoseUnit: GlucoseUnit {
        store.state.glucoseUnit
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
                                .interpolationMethod(.linear)
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

                            if let selectedPoint = selectedPoint, let glucoseValue = selectedPoint.glucose.glucoseValue {
                                PointMark(
                                    x: .value("Time", selectedPoint.valueX),
                                    y: .value("Glucose", selectedPoint.valueY)
                                )
                                .symbolSize(Config.selectionSize)
                                .opacity(0.5)
                                .foregroundStyle(
                                    (glucoseValue < store.state.alarmLow || glucoseValue > store.state.alarmHigh)
                                        ? Color.ui.red
                                        : Color.ui.blue
                                )
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
                            AxisMarks(values: .stride(by: zoomLevel?.labelEveryUnit ?? .hour, count: zoomLevel?.labelEvery ?? 1)) { value in
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
                            updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)

                        }.onChange(of: store.state.glucoseValues) { _ in
                            updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)

                        }.onChange(of: store.state.chartZoomLevel) { _ in
                            updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)

                        }.onAppear {
                            updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)

                        }.chartOverlay { proxy in
                            GeometryReader { geometryProxy in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .gesture(DragGesture()
                                        .onChanged { value in
                                            let currentX = value.location.x - geometryProxy[proxy.plotAreaFrame].origin.x

                                            if let currentDate: Date = proxy.value(atX: currentX), let currentPoint = cgmSeries.last(where: { $0.valueX == currentDate.toRounded(on: 1, .minute) }) {
                                                selectedPoint = currentPoint
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedPoint = nil
                                        }
                                    )
                            }
                        }
                    }
                }
            }

            if let selectedPoint = selectedPoint, let glucoseValue = selectedPoint.glucose.glucoseValue {
                VStack(alignment: .leading) {
                    Text(selectedPoint.glucose.timestamp.toLocalDateTime())
                    Text(glucoseValue.asGlucose(unit: glucoseUnit, withUnit: true)).bold()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundColor(.white)
                .font(.footnote)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .foregroundStyle(
                            (glucoseValue < store.state.alarmLow || glucoseValue > store.state.alarmHigh)
                                ? Color.ui.red
                                : Color.ui.blue
                        )
                        .opacity(0.5)
                )
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
            ZoomLevel(level: 48, name: LocalizedString("48h"), visibleHours: 48, labelEvery: 8, labelEveryUnit: .hour),
        ]
    }

    @State private var seriesWidth: CGFloat = 0
    @State private var cgmSeries: [ChartDatapoint] = []
    @State private var bgmSeries: [ChartDatapoint] = []
    @State private var selectedPoint: ChartDatapoint? = nil

    private let calculationQueue = DispatchQueue(label: "libre-direct.chart-calculation")

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

            self.cgmSeries = populateValues(glucoseValues: glucoseValues.filter { $0.type == .cgm })
            self.bgmSeries = populateValues(glucoseValues: glucoseValues.filter { $0.type == .bgm })

            if let scrollProxy = scrollViewProxy {
                self.scrollToEnd(scrollViewProxy: scrollProxy)
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
    let glucose: Glucose
    let isAlarm: Bool
}

// MARK: Equatable

extension ChartDatapoint: Equatable {
    static func == (lhs: ChartDatapoint, rhs: ChartDatapoint) -> Bool {
        lhs.id == rhs.id
    }
}

extension Glucose {
    func isValidCGM() -> Bool {
        type == .cgm && glucoseValue != nil
    }

    func isValidBGM() -> Bool {
        type == .bgm && glucoseValue != nil
    }

    func toDatapointID(glucoseUnit: GlucoseUnit) -> String {
        "\(id.uuidString)-\(glucoseUnit.rawValue)"
    }

    func toDatapoint(glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int) -> ChartDatapoint? {
        guard let glucoseValue = glucoseValue else {
            return nil
        }

        let isAlarm = glucoseValue < alarmLow || glucoseValue > alarmHigh

        if glucoseUnit == .mmolL {
            return ChartDatapoint(
                id: toDatapointID(glucoseUnit: glucoseUnit),
                valueX: timestamp,
                valueY: glucoseValue.asMmolL,
                glucose: self,
                isAlarm: isAlarm
            )
        }

        return ChartDatapoint(
            id: toDatapointID(glucoseUnit: glucoseUnit),
            valueX: timestamp,
            valueY: glucoseValue.asMgdL,
            glucose: self,
            isAlarm: isAlarm
        )
    }
}
