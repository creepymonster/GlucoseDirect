//
//  ToggleView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 02.08.21.
//

import SwiftUI

typealias ToggleCompletionHandler = (_ value: Bool) -> Void

struct ToggleView: View {
    let key: String
    let trueValue: String
    let falseValue: String
    let completionHandler: ToggleCompletionHandler?

    @State var value: Bool

    init(key: String, value: Bool, trueValue: String, falseValue: String, completionHandler: ToggleCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.trueValue = trueValue
        self.falseValue = falseValue
        self.completionHandler = completionHandler
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(key)
                .frame(maxWidth: 100, alignment: .leading)

            Toggle(isOn: $value, label: {
                HStack {
                    Text(falseValue)
                        .if(value) { $0.foregroundColor(.secondary.opacity(0.5)) }
                        .if(!value) { $0.foregroundColor(.accentColor) }
                        .if(!value) { $0.font(.body.bold()) }
                    
                    Text(trueValue)
                        .if(!value) { $0.foregroundColor(.secondary.opacity(0.5)) }
                        .if(value) { $0.foregroundColor(.accentColor) }
                        .if(value) { $0.font(.body.bold()) }
                }
            }).onChange(of: value, perform: { value in
                if let completionHandler = completionHandler {
                    completionHandler(value)
                }
            }).toggleStyle(SwitchToggleStyle(tint: Color.clear))
        }
    }
}

struct ToggleView_Previews: PreviewProvider {
    static var previews: some View {
        ToggleView(key: "Key", value: true, trueValue: "mg/dl", falseValue: "mmol")
        ToggleView(key: "Key", value: false, trueValue: "mg/dl", falseValue: "mmol")
    }
}
