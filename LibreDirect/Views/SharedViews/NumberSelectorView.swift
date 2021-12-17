//
//  NumberSelectorView.swift
//  LibreDirect
//

import SwiftUI

typealias NumberSelectorCompletionHandler = (_ value: Int) -> Void

// MARK: - NumberSelectorView

struct NumberSelectorView: View {
    // MARK: Lifecycle

    init(key: String, value: Int, step: Int, min: Int = 40, max: Int = 500, displayValue: String?, completionHandler: NumberSelectorCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.step = step
        self.displayValue = displayValue
        self.completionHandler = completionHandler
        self.min = Double(min)
        self.max = Double(max)
    }

    // MARK: Internal

    @State var value: Int

    let key: String
    var displayValue: String?
    let completionHandler: NumberSelectorCompletionHandler?
    let step: Int
    let min: Double
    let max: Double

    var doubleProxy: Binding<Double> {
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
                Button {
                    value = value - 1
                } label: {
                    Image(systemName: "minus")
                }
                .frame(width: 40, height: 40, alignment: .leading)
                .font(.title3)
                .foregroundColor(Color.primary)
                .buttonStyle(.borderless)

                Slider(value: doubleProxy, in: min ... max).onChange(of: value, perform: { value in
                    if let completionHandler = completionHandler {
                        completionHandler(value)
                    }
                })

                Button {
                    value = value + 1
                } label: {
                    Image(systemName: "plus")
                }
                .frame(width: 40, height: 40, alignment: .trailing)
                .font(.title3)
                .foregroundColor(Color.primary)
                .buttonStyle(.borderless)
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
