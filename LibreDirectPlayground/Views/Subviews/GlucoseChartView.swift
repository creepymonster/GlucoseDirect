//
//  GlucoseChartView.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 26.07.21.
//

import SwiftUI
import SwiftUICharts
import Combine

struct GlucoseChartView: View {
    @Environment(\.colorScheme) var colorScheme

    var glucoseValues: [SensorGlucose]
    var alarmLow: Int?
    var alarmHigh: Int?
    var targetValue: Int?

    var chartMin: Double {
        get {
            return 0
        }
    }

    var chartMax: Double {
        get {
            guard let glucoseValue = glucoseValues.max(by: { $0.glucoseFiltered < $1.glucoseFiltered }) else {
                return 0
            }

            if let alarmHigh = alarmHigh, alarmHigh >= glucoseValue.glucoseFiltered {
                return Double(alarmHigh + 20)
            }

            let roundedValue = lrint(Double(glucoseValue.glucoseFiltered) / Double(20)) * 20
            return Double(roundedValue) + 20
        }
    }

    func getColor(light: Color, dark: Color) -> Color {
        if colorScheme == .dark {
            return light
        }

        return dark
    }

    var chartData: LineChartData {
        get {
            return LineChartData(
                dataSets: LineDataSet(
                    dataPoints: glucoseValues.map {
                        LineChartDataPoint(
                            value: Double($0.glucoseFiltered),
                            date: $0.timeStamp
                        )
                    },
                    style: LineStyle(lineColour: ColourStyle(colour: getColor(light: Color.white, dark: Color.black)), lineType: .line, strokeStyle: Stroke(lineWidth: 2))
                ),
                chartStyle: LineChartStyle(
                    yAxisGridStyle: GridStyle(numberOfLines: 6, lineWidth: 1, dash: [4, 4]),
                    yAxisNumberOfLabels: 6,
                    baseline: .minimumWithMaximum(of: chartMin),
                    topLine: .maximum(of: chartMax)
                )
            )
        }
    }
    
    var body: some View {
        if glucoseValues.count > 2 {
            GroupBox(label: Text(String(format: LocalizedString("Chart (%1$@)", comment: ""), glucoseValues.count.description)).padding(.bottom).foregroundColor(.accentColor)) {
                LineChart(chartData: chartData)
                    .xAxisGrid(chartData: chartData)
                    .yAxisGrid(chartData: chartData)
                    .yAxisLabels(chartData: chartData)
                    .ifLet(alarmLow) {
                        $0.yAxisPOI(chartData: chartData,
                            markerName: LocalizedString("Lower Limit", comment: ""),
                            markerValue: Double($1),
                            labelPosition: .yAxis(specifier: "%.0f"),
                            lineColour: Color(.red).opacity(0.75),
                            strokeStyle: StrokeStyle(lineWidth: 1, dash: [8, 8])
                        )
                    }
                    .ifLet(alarmHigh) {
                        $0.yAxisPOI(chartData: chartData,
                            markerName: LocalizedString("Upper Limit", comment: ""),
                            markerValue: Double($1),
                            labelPosition: .yAxis(specifier: "%.0f"),
                            lineColour: Color(.red).opacity(0.75),
                            strokeStyle: StrokeStyle(lineWidth: 1, dash: [8, 8])
                        )
                    }
                    .ifLet(targetValue) {
                        $0.yAxisPOI(chartData: chartData,
                            markerName: LocalizedString("Normal Glucose", comment: ""),
                            markerValue: Double($1),
                            labelPosition: .yAxis(specifier: "%.0f"),
                            lineColour: getColor(light: Color.white, dark: Color.black).opacity(0.5),
                            strokeStyle: StrokeStyle(lineWidth: 1, dash: [8, 8])
                        )
                    }
                    .frame(height: 250)
                    .padding([.top])
            }
        }
    }
}

struct GlucoseChartView_Previews: PreviewProvider {
    static var previews: some View {
        let glucoseValues = [
            SensorGlucose(timeStamp: Date().addingTimeInterval(120 * 60 * -1), glucose: 185),
            SensorGlucose(timeStamp: Date().addingTimeInterval(119 * 60 * -1), glucose: 180),
            SensorGlucose(timeStamp: Date().addingTimeInterval(118 * 60 * -1), glucose: 170),
            SensorGlucose(timeStamp: Date().addingTimeInterval(117 * 60 * -1), glucose: 165),
            SensorGlucose(timeStamp: Date().addingTimeInterval(116 * 60 * -1), glucose: 150),
            SensorGlucose(timeStamp: Date().addingTimeInterval(115 * 60 * -1), glucose: 120),
            SensorGlucose(timeStamp: Date().addingTimeInterval(114 * 60 * -1), glucose: 125),
            SensorGlucose(timeStamp: Date().addingTimeInterval(113 * 60 * -1), glucose: 130),
            SensorGlucose(timeStamp: Date().addingTimeInterval(112 * 60 * -1), glucose: 125),
            SensorGlucose(timeStamp: Date().addingTimeInterval(111 * 60 * -1), glucose: 120),
            SensorGlucose(timeStamp: Date().addingTimeInterval(110 * 60 * -1), glucose: 115),
            SensorGlucose(timeStamp: Date().addingTimeInterval(109 * 60 * -1), glucose: 105)
        ]

        ForEach(ColorScheme.allCases, id: \.self) {
            GlucoseChartView(glucoseValues: glucoseValues, alarmLow: 70, alarmHigh: 180, targetValue: 100).preferredColorScheme($0)
        }
    }
}
