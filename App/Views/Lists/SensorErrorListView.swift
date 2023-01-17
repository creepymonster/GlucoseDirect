//
//  SensorErrorList.swift
//  GlucoseDirectApp
//

import SwiftUI

struct SensorErrorListView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            CollapsableSection(
                teaser: Text(getTeaser(sensorErrorValues.count)),
                header: HStack {
                    Label("Sensor error values", systemImage: "exclamationmark.triangle")
                    Spacer()
                    SelectedDatePager().padding(.trailing)
                }.buttonStyle(.plain),
                collapsed: true,
                collapsible: !sensorErrorValues.isEmpty)
            {
                if sensorErrorValues.isEmpty {
                    Text(getTeaser(sensorErrorValues.count))
                } else {
                    ForEach(sensorErrorValues) { sensorError in
                        HStack(alignment: .top) {
                            Text(verbatim: sensorError.timestamp.toLocalDateTime())
                                .monospacedDigit()

                            Spacer()

                            Text(verbatim: sensorError.error.description).multilineTextAlignment(.trailing)
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let deletables = offsets.map { i in
                            (index: i, error: sensorErrorValues[i])
                        }

                        deletables.forEach { delete in
                            sensorErrorValues.remove(at: delete.index)
                            store.dispatch(.deleteSensorError(error: delete.error))
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .onAppear {
            DirectLog.info("onAppear")
            self.sensorErrorValues = store.state.sensorErrorValues.reversed()
        }
        .onChange(of: store.state.sensorErrorValues) { errorValues in
            DirectLog.info("onChange")
            self.sensorErrorValues = errorValues.reversed()
        }
    }

    // MARK: Private

    @State private var sensorErrorValues: [SensorError] = []

    private func getTeaser(_ count: Int) -> String {
        return count.pluralizeLocalization(singular: "%@ Entry", plural: "%@ Entries")
    }
}
