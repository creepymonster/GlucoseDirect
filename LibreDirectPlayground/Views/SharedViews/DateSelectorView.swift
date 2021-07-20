//
//  DateSelectorView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 20.07.21.
//

import SwiftUI

typealias DateSelectorCompletionHandler = (_ value: Date?) -> Void

struct DateSelectorView: View {
    let key: String
    let completionHandler: DateSelectorCompletionHandler?
    var outputValue: Date?
    
    @State var value: Int = 0

    init(key: String, value: Date?, completionHandler: DateSelectorCompletionHandler? = nil) {
        self.key = key
        self.outputValue = value
        self.completionHandler = completionHandler
        
        if value == nil {
            self.value = 0
        }
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(key)
                .frame(maxWidth: 100, alignment: .leading)
           
            Stepper(value: $value, in: 0...60) {
                if let outputValue = outputValue {
                    Text("\(value) - \(outputValue.localTime)")
                }
            }.onChange(of: value, perform: { value in
                if let completionHandler = completionHandler {
                    if value == 0 {
                        completionHandler(nil)
                    } else {
                        let dateValue = Date().addingTimeInterval(Double(value) * 60) //* 5
                        completionHandler(dateValue.rounded(on: 1, .minute))
                    }
                }
            })
        }
    }
}

struct DateSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        DateSelectorView(key: "Key", value: Date())
    }
}
