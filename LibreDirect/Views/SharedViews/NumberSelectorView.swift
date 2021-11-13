//
//  NumberSelectorView.swift
//  LibreDirect
//

import SwiftUI

typealias NumberSelectorCompletionHandler = (_ value: Int) -> Void

// MARK: - NumberSelectorView

struct NumberSelectorView: View {
    // MARK: Lifecycle

    init(key: String, value: Int, step: Int, displayValue: String?, completionHandler: NumberSelectorCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.step = step
        self.displayValue = displayValue
        self.completionHandler = completionHandler
    }

    // MARK: Internal

    let key: String
    var displayValue: String?
    let completionHandler: NumberSelectorCompletionHandler?
    let step: Int

    @State var value: Int

    var body: some View {
        HStack(alignment: .center) {
            Text(key)

            Stepper(value: $value, in: 40 ... 500, step: step) {
                if let displayValue = displayValue {
                    Text(displayValue)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }.onChange(of: value, perform: { value in
                if let completionHandler = completionHandler {
                    completionHandler(value)
                }
            }).frame(minWidth: 0, maxWidth: .infinity)
        }
    }
}

// MARK: - NumberSelectorView_Previews

struct NumberSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        NumberSelectorView(key: "Key", value: 10, step: 5, displayValue: "10 mg/dl")
    }
}
