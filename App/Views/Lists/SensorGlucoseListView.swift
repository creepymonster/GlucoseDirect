//
//  SensorGlucoseList.swift
//  GlucoseDirectApp
//

import SwiftUI

struct SensorGlucoseListView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            CollapsableSection(
                teaser: Text(getTeaser(sensorGlucoseValues.count)),
                header: HStack {
                    Label("Sensor glucose values", systemImage: "sensor.tag.radiowaves.forward")
                    Spacer()
                    SelectedDatePager().padding(.trailing)
                }.buttonStyle(.plain),

                collapsed: true,
                collapsible: !sensorGlucoseValues.isEmpty)
            {
                if sensorGlucoseValues.isEmpty {
                    Text(getTeaser(sensorGlucoseValues.count))
                } else {
                    ForEach(sensorGlucoseValues) { sensorGlucose in
                        HStack {
                            Text(verbatim: sensorGlucose.timestamp.toLocalDateTime())
                                .monospacedDigit()

                            Spacer()

                            if let glucoseValue = sensorGlucose.smoothGlucoseValue?.toInteger(), sensorGlucose.timestamp < store.state.smoothThreshold, DirectConfig.showSmoothedGlucose {
                                Text(verbatim: glucoseValue.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))
                                    .monospacedDigit()
                                    .if(store.state.isAlarm(glucoseValue: glucoseValue) != .none) { text in
                                        text.foregroundColor(Color.ui.red)
                                    }
                            } else {
                                Text(verbatim: sensorGlucose.glucoseValue.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))
                                    .monospacedDigit()
                                    .if(store.state.isAlarm(glucoseValue: sensorGlucose.glucoseValue) != .none) { text in
                                        text.foregroundColor(Color.ui.red)
                                    }
                            }
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let deletables = offsets.map { i in
                            (index: i, glucose: sensorGlucoseValues[i])
                        }

                        deletables.forEach { delete in
                            sensorGlucoseValues.remove(at: delete.index)
                            store.dispatch(.deleteSensorGlucose(glucose: delete.glucose))
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .onAppear {
            DirectLog.info("onAppear")
            self.sensorGlucoseValues = store.state.sensorGlucoseValues.reversed()
        }
        .onChange(of: store.state.sensorGlucoseValues) { glucoseValues in
            DirectLog.info("onChange")
            self.sensorGlucoseValues = glucoseValues.reversed()
        }
    }

    // MARK: Private

    @State private var sensorGlucoseValues: [SensorGlucose] = []

    private func getTeaser(_ count: Int) -> String {
        return count.pluralizeLocalization(singular: "%@ Entry", plural: "%@ Entries")
    }
}
