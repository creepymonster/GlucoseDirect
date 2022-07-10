//
//  SensorGlucoseList.swift
//  GlucoseDirectApp
//

import SwiftUI

struct SensorGlucoseList: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            CollapsableSection(teaser: Text(getTeaser(sensorGlucoseValues.count)), header: Label("CGM", systemImage: "sensor.tag.radiowaves.forward"), collapsed: true, collapsible: !sensorGlucoseValues.isEmpty) {
                if sensorGlucoseValues.isEmpty {
                    Text(getTeaser(sensorGlucoseValues.count))
                } else {
                    ForEach(sensorGlucoseValues) { glucose in
                        HStack {
                            Text(glucose.timestamp.toLocalDateTime())
                            Spacer()

                            Text(glucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit, withUnit: true, precise: isPrecise(glucose: glucose)))
                                .if(glucose.glucoseValue < store.state.alarmLow || glucose.glucoseValue > store.state.alarmHigh) { text in
                                    text.foregroundColor(Color.ui.red)
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
        return count.pluralize(singular: "\(count) Entry", plural: "\(count) Entries")
    }

    private func isPrecise(glucose: SensorGlucose) -> Bool {
        if store.state.glucoseUnit == .mgdL {
            return false
        }

        return glucose.glucoseValue.isAlmost(store.state.alarmLow, store.state.alarmHigh)
    }
}
