//
//  InsulinList.swift
//  GlucoseDirectApp
//

import SwiftUI

struct InsulinDeliveryListView: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            CollapsableSection(teaser: Text(getTeaser(insulinDeliveryValues.count)), header: Label("Insulin", systemImage: "syringe"), collapsed: true, collapsible: !insulinDeliveryValues.isEmpty) {
                if insulinDeliveryValues.isEmpty {
                    Text(getTeaser(insulinDeliveryValues.count))
                } else {
                    ForEach(insulinDeliveryValues) { insulinDeliveryValue in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(verbatim: insulinDeliveryValue.starts.toLocalDateTime())
                                    .monospacedDigit()
                                
                                if insulinDeliveryValue.type == .basal {
                                    Text(verbatim: insulinDeliveryValue.ends.toLocalDateTime())
                                        .monospacedDigit()
                                }
                            }

                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(verbatim: "\(insulinDeliveryValue.units) IE")
                                    .monospacedDigit()
                                
                                Text(verbatim: insulinDeliveryValue.type.localizedDescription)
                                    .opacity(0.5)
                                    .font(.footnote)
                            }
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
