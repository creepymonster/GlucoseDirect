//
//  GlucoseChartView.swift
//  GlucoseDirect
//

import Charts
import SwiftUI

// MARK: - ChartView

struct ChartView: View {
    // MARK: Internal

    @EnvironmentObject var store: AppStore

    @State var seriesWidth: CGFloat = 0
    @State var cgmSeries: [ChartDatapoint] = []
    @State var bgmSeries: [ChartDatapoint] = []

    var showLines: Bool {
        store.state.chartShowLines
    }

    var zoomLevel: ZoomLevel? {
        Config.zoomLevels.first(where: { $0.level == store.state.chartZoomLevel })
    }

    var glucoseUnit: GlucoseUnit {
        store.state.glucoseUnit
    }

    var alarmLow: Int {
        store.state.alarmLow
    }

    var alarmHigh: Int {
        store.state.alarmHigh
    }

    var glucoseValues: [Glucose] {
        store.state.glucoseValues
    }

    @available(iOS 16.0, *)
    var ChartView: some View {
        GeometryReader { geometryProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { scrollViewProxy in
                    Chart {
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
                            .interpolationMethod(.linear)
                            .lineStyle(Config.lineStyle)
                            .foregroundStyle(Color.ui.blue)
                        }

                        ForEach(bgmSeries) { value in
                            PointMark(
                                x: .value("Time", value.valueX),
                                y: .value("Glucose", value.valueY)
                            )
                            .symbolSize(Config.symbolSize)
                            .foregroundStyle(Color.ui.red)
                        }
                    }
                    .chartPlotStyle { plotArea in
                        plotArea.padding(.vertical)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .hour)) { value in
                            if let dateValue = value.as(Date.self), let zoomLevel = zoomLevel, Calendar.current.component(.hour, from: dateValue) % zoomLevel.labelEveryHours == 0 {
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

                    }.onChange(of: store.state.chartShowLines) { _ in
                        updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)

                    }.onChange(of: store.state.chartZoomLevel) { _ in
                        updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)

                    }.onAppear {
                        updateSeries(viewWidth: geometryProxy.size.width, scrollViewProxy: scrollViewProxy)
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
                if #available(iOS 16.0, *) {
                    VStack {
                        ChartView.frame(height: 300)
                        ZoomLevelsView
                    }
                } else {
                    Text("A new iOS update is now available. Please update to iOS 16.")
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
        static let spacerWidth: CGFloat = 50
        static let lineStyle: StrokeStyle = .init(lineWidth: 2.5, lineCap: .round)
        static let ruleStyle: StrokeStyle = .init(lineWidth: 0.5, dash: [2])

        static let zoomLevels: [ZoomLevel] = [
            ZoomLevel(level: 1, name: LocalizedString("1h"), visibleHours: 1, labelEveryHours: 1),
            ZoomLevel(level: 6, name: LocalizedString("6h"), visibleHours: 6, labelEveryHours: 2),
            ZoomLevel(level: 12, name: LocalizedString("12h"), visibleHours: 12, labelEveryHours: 3),
            ZoomLevel(level: 24, name: LocalizedString("24h"), visibleHours: 24, labelEveryHours: 6),
            ZoomLevel(level: 48, name: LocalizedString("48h"), visibleHours: 48, labelEveryHours: 8)
        ]
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
        let glucoseValues = glucoseValues.filter { value in
            value.isValidCGM() || value.isValidBGM()
        }

        if let startTime = glucoseValues.first?.timestamp.timeIntervalSince1970,
           let endTime = glucoseValues.last?.timestamp.timeIntervalSince1970,
           let zoomLevel = zoomLevel
        {
            let minuteWidth = (viewWidth / CGFloat(zoomLevel.visibleHours * 60))
            let chartMinutes = CGFloat((endTime - startTime) / 60)

            seriesWidth = CGFloat(minuteWidth * chartMinutes)
        }

        cgmSeries = populateValues(glucoseValues: glucoseValues.filter { $0.type == .cgm })
        bgmSeries = populateValues(glucoseValues: glucoseValues.filter { $0.type == .bgm })

        if let scrollProxy = scrollViewProxy {
            scrollToEnd(scrollViewProxy: scrollProxy)
        }
    }

    private func populateValues(glucoseValues: [Glucose]) -> [ChartDatapoint] {
        glucoseValues.map { value in
            value.toDatapoint(glucoseUnit: glucoseUnit)
        }.compactMap { $0 }
    }
}

// MARK: - ZoomLevel

struct ZoomLevel {
    let level: Int
    let name: String
    let visibleHours: Int
    let labelEveryHours: Int
}

// MARK: - ChartDatapoint

struct ChartDatapoint: Identifiable {
    let id: String
    let valueX: Date
    let valueY: Decimal
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

    func toDatapoint(glucoseUnit: GlucoseUnit) -> ChartDatapoint? {
        guard let glucoseValue = glucoseValue else {
            return nil
        }

        if glucoseUnit == .mmolL {
            return ChartDatapoint(
                id: toDatapointID(glucoseUnit: glucoseUnit),
                valueX: timestamp,
                valueY: glucoseValue.asMmolL
            )
        }

        return ChartDatapoint(
            id: toDatapointID(glucoseUnit: glucoseUnit),
            valueX: timestamp,
            valueY: Decimal(glucoseValue)
        )
    }
}

// TEST
