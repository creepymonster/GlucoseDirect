//
//  View.swift
//  GlucoseDirect
//

import SwiftUI

extension View {
    // .if(X) { $0.padding(8) }
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

    // .if(X) { $0.padding(8) } else: { $0.background(Color.blue) }
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    // .ifLet(optionalColor) { $0.foregroundColor($1) }
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
    
    func info(_ message: String) -> some View {
        DirectLog.info(message)
        
        return self
    }
    
    func debug(_ message: String) -> some View {
        DirectLog.debug(message)
        
        return self
    }
    
    func error(_ message: String) -> some View {
        DirectLog.error(message)
        
        return self
    }
}

// TEST
