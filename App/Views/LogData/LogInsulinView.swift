//
//  LogInsulinView.swift
//  GlucoseDirectApp
//

import SwiftUI

struct LogInsulinView: View {
    @Environment(\.dismiss) var dismiss
    
    @State var starts: Date = .init()
    @State var ends: Date = .init()
    @State var units: Float?
    @State var insulinType: InsulinType = .mealBolus
    
    @FocusState private var unitsFocus: Bool
    
    var addCallback: (_ starts: Date, _ ends: Date, _ units: Float, _ insulinType: InsulinType) -> Void
    
    var body: some View {
        NavigationView {
            HStack {
                Form {
                    Section(content: {
                        HStack {
                            DatePicker(
                                "Starts",
                                selection: $starts,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }
                        
                        HStack {
                            DatePicker(
                                "Ends",
                                selection: $ends,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }
                        
                        HStack {
                            Text("Units of Insulin").font(.callout)
                            
                            TextField("", value: $units, format: .number)
                                .textFieldStyle(.automatic)
                                .keyboardType(.decimalPad)
                                .focused($unitsFocus)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        List {
                            Picker("Insulin Type", selection: $insulinType) {
                                Text("Meal Bolus").tag(InsulinType.mealBolus)
                                Text("Correction Bolus").tag(InsulinType.correctionBolus)
                                Text("Snack Bolus").tag(InsulinType.snackBolus)
                                Text("Basal").tag(InsulinType.basal)
                            }.pickerStyle(.menu)
                        }
                    }, footer: {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Basal insulin referes to the insulin used to regulate blood glucose between meals including during sleep.")
                            Text("Bolus insulin refers to the insulin used to regulate blood glucose at meals and/or to acutely address high blood glucose.")
                        }
                    })
                }
            }
            .navigationTitle("Insulin")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addCallback(starts, ends, units!, insulinType)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }.onAppear {
                // Set the units to be focused when the view opens.
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.unitsFocus = true
                }
            }
        }
    }
}

struct LogInsulinView_Previews: PreviewProvider {
    static var previews: some View {
        Button("Modal always shown") {}
            .sheet(isPresented: .constant(true)) {
                LogInsulinView { _, _, _, _ in
                }
            }
    }
}
