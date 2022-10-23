//
//  LoadingIndicator.swift
//  GlucoseDirectApp
//

import SwiftUI

struct LoadingView<Content>: View where Content: View {
    @Binding var isShowing: Bool
    var content: () -> Content

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .center) {
                self.content()
                    .disabled(self.isShowing)
                    .opacity(self.isShowing ? 0.80 : 1)
                    .blur(radius: self.isShowing ? 2 : 0)

                ProgressView()
                    .scaleEffect(2)
                    .opacity(self.isShowing ? 1 : 0)
            }
        }
    }
}
