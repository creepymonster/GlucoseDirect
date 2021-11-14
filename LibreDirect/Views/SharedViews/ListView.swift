//
//  ListView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - ListView

struct ListView: View {
    // MARK: Lifecycle

    init(rows: [ListViewRow]) {
        self.header = nil
        self.rows = rows
    }

    init(header: String, rows: [ListViewRow]) {
        self.header = header
        self.rows = rows
    }

    // MARK: Internal

    let header: String?
    let rows: [ListViewRow]

    var headerView: some View {
        if let header = header {
            return AnyView(Text(LocalizedString(header))
                .foregroundColor(.accentColor)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40))
        }

        return AnyView(EmptyView())
    }

    var body: some View {
        if rows.contains(where: { $0.isVisible }) {
            Section(header: headerView) {
                ForEach(rows) { row in
                    if row.isVisible {
                        HStack(spacing: 0) {
                            Text(LocalizedString(row.key))
                            Spacer()
                            Text(row.value ?? "-")
                        }.padding(.top, 5)
                    }
                }
            }
        }
    }
}

// MARK: - ListViewRow

struct ListViewRow: Identifiable {
    // MARK: Lifecycle

    init(key: String, value: String?, isVisible: Bool = true) {
        self.key = key
        self.value = value
        self.isVisible = value != nil && isVisible
    }

    // MARK: Internal

    let key: String
    let value: String?
    let isVisible: Bool

    var id: String {
        key
    }
}
