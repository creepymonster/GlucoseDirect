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
                    .blur(radius: self.isShowing ? 3 : 0)

                ProgressView()
                    .opacity(self.isShowing ? 1 : 0)
            }
        }
    }
}
