//
//  KeyNumberEditorView.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 19.07.21.
//

import SwiftUI

typealias NumberSelectorCompletionHandler = (_ value: Int) -> Void

struct NumberSelectorView: View {
    let key: String
    let completionHandler: NumberSelectorCompletionHandler?

    @State var value: Int

    init(key: String, value: Int, completionHandler: NumberSelectorCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.completionHandler = completionHandler
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(key)
                .frame(maxWidth: 100, alignment: .leading)
           
            Stepper(value: $value, in: 40...500, step: 5) {
                Text("\(value)")
            }.onChange(of: value, perform: { value in
                if let completionHandler = completionHandler {
                    completionHandler(value)
                }
            })
        }
    }
}

struct NumberSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        NumberSelectorView(key: "Key", value: 10)
    }
}
