//
//  KeyValueView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - KeyValueView

struct KeyValueView: View {
    // MARK: Lifecycle

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    // MARK: Internal

    let key: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(key)
                .frame(maxWidth: 100, alignment: .leading)
            
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }.padding(0)
    }
}

// MARK: - KeyValueView_Previews

struct KeyValueView_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueView(key: "Key", value: "Value")
        KeyValueView(key: "Key", value: "Value")
    }
}
