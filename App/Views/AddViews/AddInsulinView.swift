//
//  AddInsulinView.swift
//  GlucoseDirectApp
//

import SwiftUI

struct AddInsulinView: View {
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var unitsFocus: Bool
    
    @State var starts: Date = .init()
    @State var ends: Date = .init()
    @State var units: Double?
    @State var insulinType: InsulinType = .snackBolus

    var addCallback: (_ starts: Date, _ ends: Date, _ units: Double, _ insulinType: InsulinType) -> Void
    
    var body: some View {
        NavigationView {
            HStack {
                Form {
                    Section(content: {
                        List {
                            Picker("Type", selection: $insulinType) {
                                Text(InsulinType.correctionBolus.localizedDescription).tag(InsulinType.correctionBolus)
                                Text(InsulinType.mealBolus.localizedDescription).tag(InsulinType.mealBolus)
                                Text(InsulinType.snackBolus.localizedDescription).tag(InsulinType.snackBolus)
                                Text(InsulinType.basal.localizedDescription).tag(InsulinType.basal)
                            }.pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("Units")
                            
                            TextField("", value: $units, format: .number)
                                .textFieldStyle(.automatic)
                                .keyboardType(.numbersAndPunctuation)
                                .focused($unitsFocus)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        if insulinType != .basal {
                            HStack {
                                DatePicker(
                                    "Time",
                                    selection: $starts,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                            }
                        } else {
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
                        if let units = units {
                            if insulinType != .basal {
                                addCallback(starts, starts, units, insulinType)
                            } else {
                                addCallback(starts, ends, units, insulinType)
                            }
                            dismiss()
                        }
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

struct AddInsulinView_Previews: PreviewProvider {
    static var previews: some View {
        Button("Modal always shown") {}
            .sheet(isPresented: .constant(true)) {
                AddInsulinView { _, _, _, _ in
                }
            }
    }
}
