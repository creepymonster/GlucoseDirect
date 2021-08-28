//
//  KeyValueView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct KeyValueView: View {
    let key: String
    let value: String
    let valueColor: Color?

    init(key: String, value: String, valueColor: Color? = nil) {
        self.key = key
        self.value = value
        self.valueColor = valueColor
    }

    var body: some View {
        HStack(alignment: .top) {
            Text(key)
                .frame(maxWidth: 100, alignment: .leading)

            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .ifLet(valueColor) { $0.foregroundColor($1).font(Font.body.bold()) }
        }
    }
}

struct KeyValueView_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueView(key: "Key", value: "Value")
        KeyValueView(key: "Key", value: "Value", valueColor: Color.accentColor)
    }
}
