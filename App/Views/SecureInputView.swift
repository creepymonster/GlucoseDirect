//
//  SecureInputView.swift
//  GlucoseDirectApp
//
//  Created by arun on 9/23/23.
//

import SwiftUI

struct SecureInputView: View {
    @Binding private var text: String
    @State private var isVisible: Bool = false
    private var title: String

    @FocusState var inFocus: Field?
    
    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    enum Field {
        case secure, plain
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isVisible {
                    TextField(title, text: $text)
                        .focused($inFocus, equals: .plain)
                } else {
                    SecureField(title, text: $text)
                        .focused($inFocus, equals: .secure)
                }
            }.padding(.trailing, 32)
            Button(action: {
                isVisible.toggle()
            }) {
                Image(systemName: self.isVisible ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
        }.ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
