//
//  ToggleView.swift
//  LibreDirect
//

import SwiftUI

typealias ToggleCompletionHandler = (_ value: Bool) -> Void

// MARK: - ToggleView

struct ToggleView: View {
    // MARK: Lifecycle

    init(key: String, value: Bool, completionHandler: ToggleCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.trueValue = nil
        self.falseValue = nil
        self.completionHandler = completionHandler
    }

    init(key: String, value: Bool, trueValue: String, falseValue: String, completionHandler: ToggleCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.trueValue = trueValue
        self.falseValue = falseValue
        self.completionHandler = completionHandler
    }

    // MARK: Internal

    let key: String
    let trueValue: String?
    let falseValue: String?
    let completionHandler: ToggleCompletionHandler?

    @State var value: Bool

    var tintColor: Color {
        if let _ = falseValue, let _ = trueValue {
            return Color.clear
        }

        return Color.accentColor
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(key)

            Toggle(isOn: $value, label: {
                HStack {
                    if let falseValue = falseValue, let trueValue = trueValue {
                        if !value {
                            Text(falseValue)
                        } else {
                            Text(trueValue)
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .trailing)
            }).onChange(of: value, perform: { value in
                if let completionHandler = completionHandler {
                    completionHandler(value)
                }
            }).toggleStyle(SwitchToggleStyle(tint: tintColor))
        }
    }
}

// MARK: - ToggleView_Previews

struct ToggleView_Previews: PreviewProvider {
    static var previews: some View {
        ToggleView(key: "Key", value: true, trueValue: "mg/dl", falseValue: "mmol")
        ToggleView(key: "Key", value: false, trueValue: "mg/dl", falseValue: "mmol")
    }
}
