//
//  File.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 27.07.21.
//

import SwiftUI

struct LoadingView: View {
    var loadingText: String = LocalizedString("Loading", comment: "")
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Text(String(format: LocalizedString("%1$@..", comment: ""), loadingText))
                .font(.system(.body, design: .rounded))
                .bold()
                .offset(x: 0, y: 0)

            Circle()
                .trim(from: 0, to: 0.2)
                .stroke(Color.accentColor, lineWidth: 7)
                .frame(width: 150, height: 150)
                .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                .animation(Animation.linear(duration: 1)
                .repeatForever(autoreverses: false))
        }
        .padding(.vertical)
        .onAppear() {
            self.isLoading = true
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            LoadingView().preferredColorScheme($0)
            LoadingView(loadingText: "Connecting").preferredColorScheme($0)
        }
    }
}
