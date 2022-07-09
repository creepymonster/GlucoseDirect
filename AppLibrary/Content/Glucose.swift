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
}

extension Glucose {
    func isMinutly(ofMinutes: Int) -> Bool {
        let minutes = Calendar.current.component(.minute, from: timestamp)

        return minutes % ofMinutes == 0
    }

    static func == (lhs: any Glucose, rhs: any Glucose) -> Bool {
        lhs.id == rhs.id
    }
}
