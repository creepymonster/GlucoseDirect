//
//  UIScreen.swift
//  GlucoseDirect
//

import SwiftUI

extension UIScreen {
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.size.width
    }

    static var screenHeight: CGFloat {
        UIScreen.main.bounds.size.height
    }

    static var screenSize: CGSize {
        UIScreen.main.bounds.size
    }
}
