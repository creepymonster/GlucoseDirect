//
//  View.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 27.07.21. 
//

import SwiftUI

public extension View {
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
}

public struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    public func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

public extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
 
