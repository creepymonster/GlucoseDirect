//
//  InsulinList.swift
//  GlucoseDirectApp
//

import SwiftUI

struct InsulinDeliveryList: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            CollapsableSection(teaser: Text(getTeaser(insulinDeliveryValues.count)), header: Label("Insulin Delivery", systemImage: "syringe"), collapsed: true, collapsible: !insulinDeliveryValues.isEmpty) {
                if insulinDeliveryValues.isEmpty {
                    Text(getTeaser(insulinDeliveryValues.count))
                } else {
                    ForEach(insulinDeliveryValues) { insulinDeliveryValue in
                        HStack {
                            Text(verbatim: insulinDeliveryValue.starts.toLocalDateTime())
                            Spacer()
                            Text(verbatim: "\(insulinDeliveryValue.units) IE - \(insulinDeliveryValue.type.localizedDescription)")
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let deletables = offsets.map { i in
                            (index: i, insulinDelivery: insulinDeliveryValues[i])
                        }

                        deletables.forEach { delete in
                            insulinDeliveryValues.remove(at: delete.index)
                            store.dispatch(.deleteInsulinDelivery(insulinDelivery: delete.insulinDelivery))
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .onAppear {
            DirectLog.info("onAppear")
            self.insulinDeliveryValues = store.state.insulinDeliveryValues.reversed()
        }
        .onChange(of: store.state.insulinDeliveryValues) { insulinDeliveryValues in
            DirectLog.info("onChange")
            self.insulinDeliveryValues = insulinDeliveryValues.reversed()
        }
    }

    // MARK: Private

    @State private var insulinDeliveryValues: [InsulinDelivery] = []

    private func getTeaser(_ count: Int) -> String {
        return count.pluralizeLocalization(singular: "%@ Entry", plural: "%@ Entries")
    }
}
