//
//  KeyValueView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct KeyValueView: View {
    let key: String
    let value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    var body: some View {
        HStack(alignment: .top) {
            Text(key)
                .font(Font.body.weight(.semibold))
                .frame(maxWidth: 100, alignment: .leading)

            Text(value)
                .font(Font.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct KeyValueView_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueView(key: "Key", value: "Value")
    }
}
