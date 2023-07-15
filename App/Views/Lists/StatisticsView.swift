//
//  Statistics.swift
//  GlucoseDirectApp
//
//  Created by Reimar Metzen on 07.01.23.
//

import SwiftUI

struct SelectedDatePager: View {
    @EnvironmentObject var store: DirectStore

    var body: some View {
        HStack {
            Button(action: {
                setSelectedDate(addDays: -1)
            }, label: {
                Image(systemName: "arrowshape.turn.up.backward")
            }).opacity((store.state.selectedDate ?? Date()).startOfDay > store.state.minSelectedDate.startOfDay ? 0.5 : 0)
            
            Group {
                if let selectedDate = store.state.selectedDate {
                    Text(verbatim: selectedDate.toLocalDate())
                } else {
                    Text("\(DirectConfig.lastChartHours.description) hours")
                }
            }
            .monospacedDigit()
            .padding(.horizontal)
            .onTapGesture {
                store.dispatch(.setSelectedDate(selectedDate: nil))
            }
            
            Button(action: {
                setSelectedDate(addDays: +1)
            }, label: {
                Image(systemName: "arrowshape.turn.up.forward")
            }).opacity(store.state.selectedDate == nil ? 0 : 0.5)
        }
    }
    
    private func setSelectedDate(addDays: Int) {
        store.dispatch(.setSelectedDate(selectedDate: Calendar.current.date(byAdding: .day, value: +addDays, to: store.state.selectedDate ?? Date())))

        DirectNotifications.shared.hapticFeedback()
    }
}

struct StatisticsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        if let glucoseStatistics = store.state.glucoseStatistics, glucoseStatistics.maxDays >= 3 {
            Section(
                content: {
                    HStack {
                        Text("StatisticsPeriod")
                        Spacer()

                        ForEach(Config.chartLevels, id: \.days) { level in
                            let levelDisabled = level.days > glucoseStatistics.maxDays

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
                                            $0.stroke(levelDisabled ? Color.ui.gray : Color.ui.label )
                                        }
                                        .frame(width: 12, height: 12)

                                    Text(verbatim: level.name)
                                        .if(levelDisabled) {
                                            $0.strikethrough()
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(levelDisabled ? Color.ui.gray : Color.ui.label)
                                }
                            )
                            .disabled(levelDisabled)
                            .lineLimit(1)
                            .buttonStyle(.plain)
                        }
                    }

                    Group {
                        if DirectConfig.isDebug {
                            HStack {
                                Text("StatisticsPeriod")
                                Spacer()
                                Text(verbatim: "\(glucoseStatistics.fromTimestamp.toLocalDate()) - \(glucoseStatistics.toTimestamp.toLocalDate())")
                            }
                        }
                        
                        if let avg = glucoseStatistics.avg.toInteger() {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(verbatim: "AVG")
                                    Spacer()
                                    Text(avg.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))
                                }
                                
                                if store.state.showAnnotations {
                                    Text("Average (AVG) is an overall measure of blood sugars over a period of time, offering a single high-level view of where glucose has been.")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        if let stdev = glucoseStatistics.stdev.toInteger() {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(verbatim: "SD")
                                    Spacer()
                                    Text(stdev.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))
                                }
                                
                                if store.state.showAnnotations {
                                    Text("Standard Deviation (SD) is a measure of the spread in glucose readings around the average - bouncing between highs and lows results in a larger SD. The goal is the lowest SD possible, which would reflect a steady glucose level with minimal swings.")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        if DirectConfig.isDebug {
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
                        }

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
                                Text("Time in Range (TIR) or the percentage of time spent in the target glucose range between \(store.state.alarmLow.asGlucose(glucoseUnit: store.state.glucoseUnit)) - \(store.state.alarmHigh.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true)).")
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
                                Text("Time below Range (TBR) or the percentage of time spent below the target glucose of \(store.state.alarmLow.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true)).")
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
                                Text("Time above Range (TAR) or the percentage of time spent above the target glucose of \(store.state.alarmHigh.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true)).")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }.onTapGesture(count: 2) {
                        store.dispatch(.setShowAnnotations(showAnnotations: !store.state.showAnnotations))
                    }
                },
                header: {
                    Label("Statistics (\(glucoseStatistics.days.description) days)", systemImage: "lightbulb")
                }
            )
        }
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
