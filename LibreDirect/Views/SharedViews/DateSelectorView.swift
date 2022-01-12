//
//  DateSelectorView.swift
//  LibreDirect
//

import SwiftUI

typealias DateSelectorCompletionHandler = (_ value: Date?) -> Void

// MARK: - DateSelectorView

struct DateSelectorView: View {
    // MARK: Lifecycle

    init(key: String, value: Date?, displayValue: String?, completionHandler: DateSelectorCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.displayValue = displayValue
        self.completionHandler = completionHandler
    }

    // MARK: Internal

    let key: String
    var value: Date?
    var displayValue: String?
    let completionHandler: DateSelectorCompletionHandler?

    var body: some View {
        HStack(alignment: .center) {
            Text(key)

            Stepper(onIncrement: {
                let date = (value ?? Date()).toRounded(on: 15, .minute).addingTimeInterval(30 * 60)

                if let completionHandler = completionHandler {
                    completionHandler(date)
                }
            }, onDecrement: {
                let date = (value ?? Date()).toRounded(on: 15, .minute).addingTimeInterval(-30 * 60)

                if let completionHandler = completionHandler {
                    completionHandler(date)
                }
            }) {
                if let displayValue = displayValue {
                    Text(displayValue)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 5)
                }
            }
        }
    }
}

// MARK: - DateSelectorView_Previews

struct DateSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        DateSelectorView(key: "Key", value: Date(), displayValue: Date().toLocalTime())
    }
}
