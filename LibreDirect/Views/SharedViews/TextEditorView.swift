//
//  TextEditorView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

typealias TextEditorCompletionHandler = (_ value: String) -> Void

// MARK: - TextEditorView

struct TextEditorView: View {
    // MARK: Lifecycle

    init(key: String, value: String, completionHandler: TextEditorCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.completionHandler = completionHandler
    }

    // MARK: Internal

    let key: String
    let completionHandler: TextEditorCompletionHandler?

    @State var value: String

    var body: some View {
        HStack(alignment: .center) {
            Text(key)
                .frame(maxWidth: 100, alignment: .leading)

            TextField("", text: $value)
                .onChange(of: value, perform: { value in
                    if let completionHandler = completionHandler {
                        completionHandler(value)
                    }
                })
                .frame(maxWidth: .infinity, alignment: .leading)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// MARK: - ValueEditorView_Previews

struct ValueEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(key: "Key", value: "Value")
    }
}
