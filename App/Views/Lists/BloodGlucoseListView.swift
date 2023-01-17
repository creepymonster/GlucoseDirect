//
//  BloodGlucoseList.swift
//  GlucoseDirectApp
//

import SwiftUI

struct BloodGlucoseListView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            CollapsableSection(
                teaser: Text(getTeaser(bloodGlucoseValues.count)),
                header: HStack {
                    Label("Blood glucose values", systemImage: "drop")
                    Spacer()
                    SelectedDatePager().padding(.trailing)
                }.buttonStyle(.plain),
                collapsed: true,
                collapsible: !bloodGlucoseValues.isEmpty)
            {
                if bloodGlucoseValues.isEmpty {
                    Text(getTeaser(bloodGlucoseValues.count))
                } else {
                    ForEach(bloodGlucoseValues) { bloodGlucose in
                        HStack {
                            Text(verbatim: bloodGlucose.timestamp.toLocalDateTime())
                                .monospacedDigit()

                            Spacer()

                            Text(verbatim: bloodGlucose.glucoseValue.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true))
                                .monospacedDigit()
                                .if(store.state.isAlarm(glucoseValue: bloodGlucose.glucoseValue) != .none) { text in
                                    text.foregroundColor(Color.ui.red)
                                }
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let deletables = offsets.map { i in
                            (index: i, glucose: bloodGlucoseValues[i])
                        }

                        deletables.forEach { delete in
                            bloodGlucoseValues.remove(at: delete.index)
                            store.dispatch(.deleteBloodGlucose(glucose: delete.glucose))
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .onAppear {
            DirectLog.info("onAppear")
            self.bloodGlucoseValues = store.state.bloodGlucoseValues.reversed()
        }
        .onChange(of: store.state.bloodGlucoseValues) { glucoseValues in
            DirectLog.info("onChange")
            self.bloodGlucoseValues = glucoseValues.reversed()
        }
    }

    // MARK: Private

    @State private var bloodGlucoseValues: [BloodGlucose] = []

    private func getTeaser(_ count: Int) -> String {
        return count.pluralizeLocalization(singular: "%@ Entry", plural: "%@ Entries")
    }
}
