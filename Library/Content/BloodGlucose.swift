//
//  BloodGlucose.swift
//  GlucoseDirect
//

import Foundation

// MARK: - BloodGlucose

struct BloodGlucose: Glucose, CustomStringConvertible, Codable, Identifiable {
    // MARK: Lifecycle

    init(timestamp: Date, glucoseValue: Int) {
        self.init(id: UUID(), timestamp: timestamp, glucoseValue: glucoseValue)
    }

    init(id: UUID, timestamp: Date, glucoseValue: Int) {
        self.init(id: id, timestamp: timestamp, glucoseValue: glucoseValue, originatingSourceName: DirectConfig.projectName, originatingSourceBundle: DirectConfig.appBundle)
    }
    
    init(id: UUID, timestamp: Date, glucoseValue: Int, originatingSourceName: String, originatingSourceBundle: String) {
        self.init(id: id, timestamp: timestamp, glucoseValue: glucoseValue, originatingSourceName: originatingSourceName, originatingSourceBundle: originatingSourceBundle, appleHealthId: nil)
    }
    
    init(id: UUID, timestamp: Date, glucoseValue: Int, originatingSourceName: String, originatingSourceBundle: String, appleHealthId: UUID?) {
        let roundedTimestamp = timestamp.toRounded(on: 1, .minute)
        self.id = id
        self.timestamp = roundedTimestamp
        self.glucoseValue = glucoseValue
        self.timegroup = roundedTimestamp.toRounded(on: DirectConfig.timegroupRounding, .minute)
        self.originatingSourceName = originatingSourceName
        self.originatingSourceBundle = originatingSourceBundle
        self.appleHealthId = appleHealthId
    }

    // MARK: Internal

    internal let id: UUID
    let timestamp: Date
    let glucoseValue: Int
    let timegroup: Date
    let originatingSourceName: String
    let originatingSourceBundle: String
    var appleHealthId: UUID?
    
    var description: String {
        "{ id: \(id), timestamp: \(timestamp.toLocalTime()), glucoseValue: \(glucoseValue.description), originatingSourceName: \(originatingSourceName), originatingSourceBundle: \(originatingSourceBundle), appleHealthId: \(appleHealthId) }"
    }
    
    public func isExternal() -> Bool {
        return self.originatingSourceBundle != DirectConfig.appBundle
    }
}
