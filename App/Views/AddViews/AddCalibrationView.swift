//
//  AddCalibrationView.swift
//  GlucoseDirectApp
//
//  Created by Reimar Metzen on 07.01.23.
//

import SwiftUI

struct AddCalibrationView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var value: Int = 100
    
    var glucoseSuggestion: Int
    var glucoseUnit: GlucoseUnit
    var addCallback: (_ value: Int) -> Void
    
    var body: some View {
        NavigationView {
            HStack {
                Form {
                    Section {
                        NumberSelectorView(key: LocalizedString("Glucose"), value: glucoseSuggestion, step: 1, displayValue: value.asGlucose(glucoseUnit: glucoseUnit, withUnit: true)) { value in
                            self.value = value
                        }
                    }
                }
            }
            .navigationTitle("Calibration")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addCallback(value)
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

