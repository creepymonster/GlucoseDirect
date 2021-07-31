//
//  View.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 27.07.21.
//

import SwiftUI

extension View {
    // .ifLet(optionalColor) { $0.foregroundColor($1) }
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    // .if(X) { $0.padding(8) }
    @ViewBuilder
    func ifLet<V, Transform: View>(
        _ value: V?,
        transform: (Self, V) -> Transform
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}
