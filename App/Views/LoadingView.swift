//
//  LoadingIndicator.swift
//  GlucoseDirectApp
//

import SwiftUI

struct LoadingView<Content>: View where Content: View {
    @Binding var isShowing: Bool
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                self.content()
                    .disabled(self.isShowing)
                    .opacity(self.isShowing ? 0.5 : 1)
                    .blur(radius: self.isShowing ? 2 : 0)

                VStack {
                    ProgressView()
                        .scaleEffect(2)
                        .opacity(self.isShowing ? 1 : 0)
                        .padding(.top, 48)
                        .tint(Color(uiColor: UIColor.systemBackground))
                    
                    Text("Loading...")
                        .padding(.top, 48)
                        .padding(.bottom, 32)
                        .foregroundColor(Color(uiColor: UIColor.systemBackground))
                }
                .frame(width: geometry.size.width / 2)
                .background(Color(uiColor: UIColor.label))
                .cornerRadius(10)
                .opacity(self.isShowing ? 0.75 : 0)
            }
        }
    }
}
