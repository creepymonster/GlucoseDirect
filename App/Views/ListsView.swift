//
//  ListView.swift
//  GlucoseDirect
//

import SwiftUI

// MARK: - ListView

struct ListsView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        List {
            BloodGlucoseList()
            SensorGlucoseList()
            SensorErrorList()

            if let glucoseStatistics = store.state.glucoseStatistics {
                Section(
                    content: {
                        if glucoseStatistics.days >= requiredDays {
                            Group {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("AVG")
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
                                        Text("SD")
                                        Spacer()
                                        Text(glucoseStatistics.stdev.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))
                                    }
                                    
                                    if store.state.showAnnotations {
                                        Text("Standard Deviation (SD) is a measure of the spread in glucose readings around the average - bouncing between many highs and lows results in a larger SD. The goal is the lowest SD possible, which would reflect a steady glucose level with minimal swings.")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("GMI")
                                        Spacer()
                                        Text(glucoseStatistics.gmi.asPercent())
                                    }
                                    
                                    if store.state.showAnnotations {
                                        Text("Glucose Management Indicator (GMI) is an replacement for \"estimated HbA1c\" for patients using continuous glucose monitoring.")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("TIR")
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
                                        Text("TBR")
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
                                        Text("TAR")
                                        Spacer()
                                        Text(glucoseStatistics.tar.asPercent())
                                    }
                                    
                                    if store.state.showAnnotations {
                                        Text("Time above Range (TAR) or the percentage of time spent above the target glucose of \(store.state.alarmHigh.asGlucose(unit: store.state.glucoseUnit, withUnit: true)).")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }.onTapGesture(count: 2) {
                                store.dispatch(.setShowAnnotations(showAnnotations: !store.state.showAnnotations))
                            }
                        } else {
                            Text("At least \(requiredDays) days of data are required.")
                        }
                    },
                    header: {
                        Label("Statistics (\(glucoseStatistics.days) days)", systemImage: "lightbulb")
                    }
                )
            }
        }.listStyle(.grouped)
    }

    // MARK: Private

    private let requiredDays = 14
}
