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

    @State var value: Int

    let key: String
    var displayValue: String?
    let completionHandler: NumberSelectorCompletionHandler?
    let step: Int

    var intProxy: Binding<Double> {
        Binding<Double>(get: {
            Double(value)
        }, set: {
            value = Int($0)
        })
    }

    var body: some View {
        VStack {
            HStack {
                Text(key)
                Spacer()
                
                if let displayValue = displayValue {
                    Text(displayValue)
                }
            }.padding(.top, 5)

            HStack {
                Button() {
                    value = value - 1
                } label: {
                    Image(systemName: "minus").frame(height: 50).padding(.horizontal, 20)
                }
                .padding(.leading, -20)
                .font(.title3)
                .foregroundColor(Color.primary)
                .buttonStyle(.plain)
                
                Slider(value: intProxy, in: 40 ... 500).onChange(of: value, perform: { value in
                    if let completionHandler = completionHandler {
                        completionHandler(value)
                    }
                })
                
                Button {
                    value = value + 1
                } label: {
                    Image(systemName: "plus").frame(height: 50).padding(.horizontal, 20)
                }
                .padding(.trailing, -20)
                .font(.title3)
                .foregroundColor(Color.primary)
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - NumberSelectorView_Previews

struct NumberSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        NumberSelectorView(key: "Key", value: 10, step: 5, displayValue: "10 mg/dl")
    }
}
