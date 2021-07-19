//
//  KeyNumberEditorView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 19.07.21.
//

import SwiftUI

typealias NumberEditorCompletionHandler = (_ value: Int) -> Void

struct KeyNumberEditorView: View {
    let key: String
    let completionHandler: NumberEditorCompletionHandler?
    
    @State var value: String
    
    init(key: String, value: String, completionHandler: NumberEditorCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.completionHandler = completionHandler
    }
    
    init(key: String, value: Int, completionHandler: NumberEditorCompletionHandler? = nil) {
        self.key = key
        self.value = String(value)
        self.completionHandler = completionHandler
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(key)
                .font(Font.body.weight(.semibold))
                .frame(maxWidth: 100, alignment: .leading)

            TextField("", text: $value)
                .keyboardType(.numberPad)
                .onChange(of: value, perform: { value in
                    if let completionHandler = completionHandler, let value = Int(value) {
                        completionHandler(value)
                    }
                })
                .font(Font.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct KeyNumberEditorView_Previews: PreviewProvider {
    static var previews: some View {
        KeyTextEditorView(key: "Key", value: "Value")
    }
}
