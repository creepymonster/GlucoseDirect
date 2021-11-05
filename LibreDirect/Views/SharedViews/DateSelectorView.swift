//
//  DateSelectorView.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 20.07.21.
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
                .frame(maxWidth: 100, alignment: .leading)

            Stepper(onIncrement: {
                let date = (value ?? Date()).rounded(on: 15, .minute).addingTimeInterval(30 * 60)

                if let completionHandler = completionHandler {
                    completionHandler(date)
                }
            }, onDecrement: {
                let date = (value ?? Date()).rounded(on: 15, .minute).addingTimeInterval(-30 * 60)

                if let completionHandler = completionHandler {
                    completionHandler(date)
                }
            }) {
                if let displayValue = displayValue {
                    Text(displayValue)
                }
            }
        }
    }
}

// MARK: - DateSelectorView_Previews

struct DateSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        DateSelectorView(key: "Key", value: Date(), displayValue: Date().localTime)
    }
}
