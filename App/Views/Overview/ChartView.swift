//
//  GlucoseChartView.swift
//  GlucoseDirect
//

import Charts
import SwiftUI

// MARK: - ChartView

struct ChartView: View {
    // MARK: Internal

    @Environment(\.colorScheme) var colorScheme
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

    @available(iOS 16.0, *)
    var ChartView: some View {
        GeometryReader { geometryProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { scrollViewProxy in
                    Chart {
                        RuleMark(y: .value("Lower limit", store.state.alarmLow))
                            .foregroundStyle(.red)
                            .lineStyle(Config.ruleStyle)

                        RuleMark(y: .value("Upper limit", store.state.alarmHigh))
                            .foregroundStyle(.red)
                            .lineStyle(Config.ruleStyle)

                        ForEach(cgmSeries) { value in
                            if showLines {
                                LineMark(
                                    x: .value("Time", value.valueX),
                                    y: .value("Glucose", value.valueY)
                                )
                                .lineStyle(Config.lineStyle)
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.primary)
                            } else {
                                PointMark(
                                    x: .value("Time", value.valueX),
                                    y: .value("Glucose", value.valueY)
                                )
                                .symbolSize(Config.symbolSize)
                                .foregroundStyle(.primary)
                            }
                        }

                        ForEach(bgmSeries) { value in
                            PointMark(
                                x: .value("Time", value.valueX),
                                y: .value("Glucose", value.valueY)
                            )
                            .symbolSize(Config.symbolSize)
                            .foregroundStyle(.red)
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
                                $0.fill(.primary)
                            } else: {
                                $0.stroke(.primary)
                            }
                            .frame(width: 12, height: 12)

                        Text(zoom.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                ).buttonStyle(.plain)

                Spacer()
            }

            Button(
                action: {
                    store.dispatch(.setChartShowLines(enabled: !showLines))
                },
                label: {
                    Rectangle()
                        .if(showLines) {
                            $0.fill(.primary)
                        } else: {
                            $0.stroke(.primary)
                        }
                        .frame(width: 12, height: 12)

                    Text("Line")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            ).buttonStyle(.plain)
        }
    }

    var body: some View {
        Section(
            content: {
                if #available(iOS 16.0, *) {
                    VStack {
                        ChartView.frame(height: 300)
                        ZoomLevelsView.padding(.top)
                    }
                } else {
                    Text("A new iOS update is now available. Please update to iOS 16.")
                }
            },
            header: {
                Label("Chart (\(store.state.glucoseValues.count))", systemImage: "chart.xyaxis.line")
            }
        )
    }

    // MARK: Private

    private enum Config {
        static let chartID = "chart"
        static let symbolSize: CGFloat = 10
        static let spacerWidth: CGFloat = 50
        static let lineStyle: StrokeStyle = .init(lineWidth: 2)
        static let ruleStyle: StrokeStyle = .init(lineWidth: 0.5, dash: [2])

        static let zoomLevels: [ZoomLevel] = [
            ZoomLevel(level: 1, name: LocalizedString("1h"), visibleHours: 1, labelEveryHours: 1),
            ZoomLevel(level: 5, name: LocalizedString("6h"), visibleHours: 6, labelEveryHours: 1),
            ZoomLevel(level: 15, name: LocalizedString("12h"), visibleHours: 12, labelEveryHours: 2),
            ZoomLevel(level: 30, name: LocalizedString("24h"), visibleHours: 24, labelEveryHours: 4),
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
        let glucoseValues = store.state.glucoseValues.filter { value in
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

        if isSelectedZoomLevel(level: 1) {
            cgmSeries = populateValues(glucoseValues: glucoseValues.filter { $0.type == .cgm })
        } else if let zoomLevel = zoomLevel {
            cgmSeries = populateZoomedValues(glucoseValues: glucoseValues.filter { $0.type == .cgm }, glucoseValueType: .cgm, groupMinutes: zoomLevel.level)
        } else {
            cgmSeries = populateValues(glucoseValues: glucoseValues.filter { $0.type == .cgm })
        }

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

    private func populateZoomedValues(glucoseValues: [Glucose], glucoseValueType: GlucoseValueType, groupMinutes: Int) -> [ChartDatapoint] {
        let filteredValues = glucoseValues.map { value in
            (value.timestamp.toRounded(on: groupMinutes, .minute), value.glucoseValue!)
        }

        let groupedValues: [Date: [(Date, Int)]] = Dictionary(grouping: filteredValues, by: { $0.0 })

        return groupedValues.map { group in
            let sum = group.value.reduce(0) { $0 + $1.1 }
            let mean = sum / group.value.count

            return Glucose(id: UUID(), timestamp: group.key, glucose: mean, type: glucoseValueType).toDatapoint(glucoseUnit: glucoseUnit)
        }.compactMap { $0 }.sorted(by: { $0.valueX < $1.valueX })
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
        type == .cgm && quality == .OK && glucoseValue != nil
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
