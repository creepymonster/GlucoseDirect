//
//  KeyValueView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - KeyValueView

struct KeyValueView: View {
    // MARK: Lifecycle

    init(key: String, value: String, valueColor: Color? = nil) {
        self.key = key
        self.value = value
        self.valueColor = valueColor
    }

    // MARK: Internal

    let key: String
    let value: String
    let valueColor: Color?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(key)
                .frame(maxWidth: 100, alignment: .leading)

            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .ifLet(valueColor) { $0.foregroundColor($1).font(Font.body.bold()) }
        }.padding(0)
    }
}

// MARK: - KeyValueView_Previews

struct KeyValueView_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueView(key: "Key", value: "Value")
        KeyValueView(key: "Key", value: "Value", valueColor: Color.accentColor)
    }
}
