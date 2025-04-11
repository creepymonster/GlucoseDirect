//
//  Glucose.swift
//  GlucoseDirect
//

import Foundation

// MARK: - Glucose

protocol Glucose: Equatable {
    var id: UUID { get }
    var timestamp: Date { get }
    var glucoseValue: Int { get }

    static func == (lhs: Self, rhs: Self) -> Bool
}

extension Glucose {
    func isMinutly(ofMinutes: Int) -> Bool {
        let minutes = Calendar.current.component(.minute, from: timestamp)

        return minutes % ofMinutes == 0
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
