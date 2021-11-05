//
//  ValueView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

// MARK: - ValueView

struct ValueView: View {
    // MARK: Lifecycle

    init(value: String) {
        self.value = value
    }

    // MARK: Internal

    let value: String

    var body: some View {
        Text(value)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ValueView_Previews

struct ValueView_Previews: PreviewProvider {
    static var previews: some View {
        ValueView(value: "Value")
    }
}
