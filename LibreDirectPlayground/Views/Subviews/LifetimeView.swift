//
//  SensorLife.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 06.07.21.
//

import SwiftUI
import SwiftUICharts

struct LifetimeView: View {
    var sensor: Sensor?

    var chartData: PieChartData? {
        get {
            guard let sensor = sensor, let age = sensor.age, let remainingLifetime = sensor.remainingLifetime else {
                return nil
            }

            return PieChartData(
                dataSets: PieDataSet(
                    dataPoints: [
                        PieChartDataPoint(value: Double(age), colour: Color.accentColor),
                        PieChartDataPoint(value: Double(remainingLifetime), colour: Color.gray.opacity(0.2))
                    ],
                    legendTitle: ""
                ),
                metadata: ChartMetadata()
            )
        }
    }

    var body: some View {
        if let sensor = sensor {
            GroupBox(label: Text("Sensor Lifetime").padding(.bottom).foregroundColor(.accentColor)) {
                KeyValueView(key: LocalizedString("Sensor State", comment: ""), value: sensor.state.description)
                
                HStack(alignment: .center, spacing: 0) {
                    VStack {
                        KeyValueView(key: LocalizedString("Sensor Possible Lifetime", comment: ""), value: sensor.lifetime.inTime).padding(.top, 5)

                        if let age = sensor.age {
                            KeyValueView(key: LocalizedString("Sensor Age", comment: ""), value: age.inTime).padding(.top, 5)
                        }

                        if let remainingLifetime = sensor.remainingLifetime {
                            KeyValueView(key: LocalizedString("Sensor Remaining Lifetime", comment: ""), value: remainingLifetime.inTime).padding(.top, 5)
                        }
                    }

                    if let chartData = chartData {
                        PieChart(chartData: chartData)
                            .frame(width: 50, height: 50, alignment: .center)
                    }
                }
            }
        }
    }
}

struct LifetimeView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            LifetimeView(sensor: previewSensor).preferredColorScheme($0)
        }
    }
}
