//
//  ListView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ListsView

struct ListsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        List {
            BloodGlucoseList()
            SensorGlucoseList()
            SensorErrorList()

            if let glucoseStatistics = store.state.glucoseStatistics, glucoseStatistics.maxDays >= 3 {
                Section(
                    content: {
                        HStack {
                            Text("StatisticsPeriod")
                            Spacer()

                            ForEach(Config.chartLevels, id: \.days) { level in
                                Spacer()
                                Button(
                                    action: {
                                        DirectNotifications.shared.hapticFeedback()
                                        store.dispatch(.setStatisticsDays(days: level.days))
                                    },
                                    label: {
                                        Circle()
                                            .if(isSelectedChartLevel(days: level.days)) {
                                                $0.fill(Color.ui.label)
                                            } else: {
                                                $0.stroke(Color.ui.label)
                                            }
                                            .frame(width: 12, height: 12)

                                        Text(verbatim: level.name)
                                            .font(.subheadline)
                                            .foregroundColor(Color.ui.label)
                                    }
                                )
                                .disabled(level.days > glucoseStatistics.maxDays)
                                .lineLimit(1)
                                .buttonStyle(.plain)
                            }
                        }

                        Group {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(verbatim: "AVG")
                                    Spacer()
                                    Text(glucoseStatistics.avg.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))
                                }

                                if store.state.showAnnotations {
                                    Text("Average (AVG) is an overall measure of blood sugars over a period of time, offering a single high-level view of where glucose has been.")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(verbatim: "SD")
                                    Spacer()
                                    Text(glucoseStatistics.stdev.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))
                                }

                                if store.state.showAnnotations {
                                    Text("Standard Deviation (SD) is a measure of the spread in glucose readings around the average - bouncing between highs and lows results in a larger SD. The goal is the lowest SD possible, which would reflect a steady glucose level with minimal swings.")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }

                            #if DEBUG
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(verbatim: "CV")
                                    Spacer()
                                    Text(glucoseStatistics.cv.asPercent())
                                }

                                if store.state.showAnnotations {
                                    Text("Coefficient of variation (CV) is defined as the ratio of the standard deviation to the mean. Generally speaking, most experts like to see a CV of 33% or lower, which is considered a marker of “stable” glucose levels. But take note, very young patients with diabetes tend to have higher variability than adults.")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }
                            #endif

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(verbatim: "GMI")
                                    Spacer()
                                    Text(glucoseStatistics.gmi.asPercent(0.1))
                                }

                                if store.state.showAnnotations {
                                    Text("Glucose Management Indicator (GMI) is an replacement for \"estimated HbA1c\" for patients using continuous glucose monitoring.")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(verbatim: "TIR")
                                    Spacer()
                                    Text(glucoseStatistics.tir.asPercent())
                                }

                                if store.state.showAnnotations {
                                    Text("Time in Range (TIR) or the percentage of time spent in the target glucose range between \(store.state.alarmLow.asGlucose(unit: store.state.glucoseUnit)) - \(store.state.alarmHigh.asGlucose(unit: store.state.glucoseUnit, withUnit: true)).")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(verbatim: "TBR")
                                    Spacer()
                                    Text(glucoseStatistics.tbr.asPercent())
                                }

                                if store.state.showAnnotations {
                                    Text("Time below Range (TBR) or the percentage of time spent below the target glucose of \(store.state.alarmLow.asGlucose(unit: store.state.glucoseUnit, withUnit: true)).")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(verbatim: "TAR")
                                    Spacer()
                                    Text(glucoseStatistics.tar.asPercent())
                                }

                                if store.state.showAnnotations {
                                    Text("Time above Range (TAR) or the percentage of time spent above the target glucose of \(store.state.alarmHigh.asGlucose(unit: store.state.glucoseUnit, withUnit: true)).")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }

                            #if DEBUG
                            HStack {
                                Text(verbatim: "From")
                                Spacer()
                                Text(glucoseStatistics.fromTimestamp.toLocalDate())
                            }

                            HStack {
                                Text(verbatim: "To")
                                Spacer()
                                Text(glucoseStatistics.toTimestamp.toLocalDate())
                            }
                            #endif
                        }.onTapGesture(count: 2) {
                            store.dispatch(.setShowAnnotations(showAnnotations: !store.state.showAnnotations))
                        }
                    },
                    header: {
                        Label("Statistics (\(glucoseStatistics.days.description) days)", systemImage: "lightbulb")
                    }
                )
            }
        }.listStyle(.grouped)
    }

    // MARK: Private

    private enum Config {
        static let chartLevels: [ChartLevel] = [
            ChartLevel(days: 3, name: "3d"),
            ChartLevel(days: 7, name: "7d"),
            ChartLevel(days: 30, name: "30d"),
            ChartLevel(days: 90, name: "90d")
        ]
    }

    private var chartLevel: ChartLevel? {
        return Config.chartLevels.first(where: { $0.days == store.state.statisticsDays }) ?? Config.chartLevels.first
    }

    private func isSelectedChartLevel(days: Int) -> Bool {
        if let chartLevel = chartLevel, chartLevel.days == days {
            return true
        }

        return false
    }
}

// MARK: - ChartLevel

private struct ChartLevel {
    let days: Int
    let name: String
}
