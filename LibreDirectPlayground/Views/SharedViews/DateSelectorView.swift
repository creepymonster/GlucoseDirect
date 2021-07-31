//
//  DateSelectorView.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 20.07.21.
//

import SwiftUI

typealias DateSelectorCompletionHandler = (_ value: Date?) -> Void

struct DateSelectorView: View {
    let key: String
    let completionHandler: DateSelectorCompletionHandler?
    var value: Date?

    init(key: String, value: Date?, completionHandler: DateSelectorCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.completionHandler = completionHandler
    }

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
                if let outputValue = value {
                    Text("\(outputValue.localTime)")
                }
            }
        }
    }
}

struct DateSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        DateSelectorView(key: "Key", value: Date())
    }
}
