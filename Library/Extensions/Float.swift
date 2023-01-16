//
//  Float.swift
//  GlucoseDirectApp
//
//  Created by Reimar Metzen on 16.01.23.
//

import Foundation

extension Float {
    func asPercent(_ increment: Double = 1) -> String {
        return self.formatted(.percent.scale(1.0).rounded(increment: increment))
    }
}
