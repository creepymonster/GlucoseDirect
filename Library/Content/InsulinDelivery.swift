//
//  Insulin.swift
//  GlucoseDirectApp
//

import Foundation

// MARK: - Insulin


enum InsulinType: Codable {
    case bolus
    case basal
    
    func display() -> String {
        switch self {
        case .bolus:
            return  "Bolus"
        case .basal:
            return  "Basal"
        }
    }
}

struct InsulinDelivery: CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle
    
    init(starts: Date, ends: Date, units: Float, type: InsulinType) {
        let roundedStarts = starts.toRounded(on: 1, .minute)
        let roundedEnds = ends.toRounded(on: 1, .minute)
        
        self.id = UUID()
        self.starts = roundedStarts
        self.ends = roundedEnds
        self.units = units
        self.type = type
        self.timegroup = starts.toRounded(on: DirectConfig.timegroupRounding, .minute)
    }
    
    init(id: UUID, starts: Date, ends: Date, units: Float, type: InsulinType) {
        let roundedStarts = starts.toRounded(on: 1, .minute)
        let roundedEnds = ends.toRounded(on: 1, .minute)
        
        self.id = id
        self.starts = roundedStarts
        self.ends = roundedEnds
        self.units = units
        self.type = type
        self.timegroup = starts.toRounded(on: DirectConfig.timegroupRounding, .minute)
    }
    
    // MARK: Internal
    
    let id: UUID
    let starts: Date
    let ends: Date
    let units: Float
    let type: InsulinType
    let timegroup: Date
    
    var description: String {
        "{ id: \(id), starts: \(starts.toLocalTime()), ends: \(ends.toLocalTime()), units: \(units), type: \(type)}"
    }
}

// MARK: Equatable

extension InsulinDelivery: Equatable {
    func isMinutly(ofMinutes: Int) -> Bool {
        let minutes = Calendar.current.component(.minute, from: starts)
        
        return minutes % ofMinutes == 0
    }
    
    static func == (lhs: InsulinDelivery, rhs: InsulinDelivery) -> Bool {
        lhs.id == rhs.id
    }
}
