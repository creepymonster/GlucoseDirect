//
//  LogBloodGlucoseView.swift
//  GlucoseDirectApp
//
//  Created by Reimar Metzen on 07.01.23.
//

import SwiftUI

struct LogBloodGlucoseView: View {
    @Environment(\.dismiss) var dismiss

    @State var time: Date = .init()
    @State private var value: Int = 100

    var glucoseUnit: GlucoseUnit
    var addCallback: (_ time: Date, _ value: Int) -> Void
    
    var body: some View {
        NavigationView {
            HStack {
                Form {
                    Section {
                        HStack {
                            DatePicker(
                                "Time",
                                selection: $time,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }
                        
                        NumberSelectorView(key: LocalizedString("Glucose value"), value: 100, step: 1, displayValue: value.asGlucose(glucoseUnit: glucoseUnit, withUnit: true)) { value in
                            self.value = value
                        }
                    }
                }
            }
            .navigationTitle("Blood glucose")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addCallback(time, value)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
