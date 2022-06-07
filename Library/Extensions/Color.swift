//
//  Color.swift
//  GlucoseDirect
//

import Foundation
import SwiftUI

infix operator |: AdditionPrecedence
extension Color {
    static let ui = Color.UI()

    static func | (lightMode: Color, darkMode: Color) -> Color {
        return UITraitCollection.current.userInterfaceStyle == .light ? lightMode : darkMode
    }

    struct UI {
        // #FF5722, R 255, G 87, B 34
        let red = Color(.sRGB, red: 1.0, green: 0.34, blue: 0.13)

        // #42B549, R 66, G 181, B 73
        let green = Color(.sRGB, red: 0.26, green: 0.71, blue: 0.29)

        // #3094C3, R 48, G 148, B 195
        let blue = Color(.sRGB, red: 0.19, green: 0.58, blue: 0.76)
    }
}
