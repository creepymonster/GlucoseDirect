//
//  ValueView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

struct ValueView: View {
    let value: String

    init(value: String) {
        self.value = value
    }

    var body: some View {
        Text(value)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ValueView_Previews: PreviewProvider {
    static var previews: some View {
        ValueView(value: "Value")
    }
}
