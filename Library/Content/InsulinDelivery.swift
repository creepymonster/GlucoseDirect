//
//  Insulin.swift
//  GlucoseDirectApp
//

import Foundation

// MARK: - Insulin

enum InsulinType: Codable {
    case mealBolus
    case snackBolus
    case correctionBolus
    case basal

    // MARK: Internal

    var description: String {
        switch self {
        case .mealBolus:
            return "Meal Bolus"
        case .snackBolus:
            return "Snack Bolus"
        case .correctionBolus:
            return "Correction Bolus"
        case .basal:
            return "Basal"
        }
    }

    var localizedDescription: String {
        LocalizedString(description)
    }    
}

struct InsulinDelivery: CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle
    init(starts: Date, ends: Date, units: Float, type: InsulinType) {
        self.init(id: UUID(), starts: starts, ends: ends, units: units, type: type)
    }
    
    init(id: UUID, starts: Date, ends: Date, units: Float, type: InsulinType) {
        self.init(id: id, starts: starts, ends: ends, units: units, type: type, originatingSourceName: DirectConfig.projectName, originatingSourceBundle: DirectConfig.appBundle)
    }
    

    init(id: UUID, starts: Date, ends: Date, units: Float, type: InsulinType, originatingSourceName: String, originatingSourceBundle: String) {
        self.init(id: id, starts: starts, ends: ends, units: units, type: type, originatingSourceName: originatingSourceName, originatingSourceBundle: originatingSourceBundle, appleHealthId: nil)
    }
    
    init(id: UUID, starts: Date, ends: Date, units: Float, type: InsulinType, originatingSourceName: String, originatingSourceBundle: String, appleHealthId: UUID?) {
        let roundedStarts = starts.toRounded(on: 1, .minute)
        let roundedEnds = ends.toRounded(on: 1, .minute)

        self.id = id
        self.starts = roundedStarts
        self.ends = roundedEnds
        self.units = units
        self.type = type
        self.timegroup = starts.toRounded(on: DirectConfig.timegroupRounding, .minute)
        self.originatingSourceName = originatingSourceName
        self.originatingSourceBundle = originatingSourceBundle
        self.appleHealthId = appleHealthId
    }

    // MARK: Internal

    let id: UUID
    let starts: Date
    let ends: Date
    let units: Float
    let type: InsulinType
    let timegroup: Date
    var appleHealthId: UUID?
    let originatingSourceName: String
    let originatingSourceBundle: String

    var description: String {
        "{ id: \(id), starts: \(starts.toLocalTime()), ends: \(ends.toLocalTime()), units: \(units), type: \(type), originatingSourceName: \(originatingSourceName), originatingSourceBundle: \(originatingSourceBundle), appleHealthId: \(appleHealthId)}"
    }
    
    public func isSyncedToAppleHealth() -> Bool {
        return appleHealthId != nil
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
