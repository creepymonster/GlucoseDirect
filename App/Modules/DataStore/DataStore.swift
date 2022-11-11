//
//  DataStore.swift
//  GlucoseDirectApp
//
//  https://github.com/groue/GRDB.swift
//

import Combine
import Foundation
import GRDB

// MARK: - DataStore

class DataStore {
    // MARK: Lifecycle

    private init() {
        do {
            dbQueue = try DatabaseQueue(path: databaseURL.absoluteString)
        } catch {
            DirectLog.error("\(error)")
            dbQueue = nil
        }
    }

    deinit {
        do {
            try dbQueue?.close()
        } catch {
            DirectLog.error("\(error)")
        }
    }

    // MARK: Internal

    static let shared = DataStore()

    let dbQueue: DatabaseQueue?

    var databaseURL: URL = {
        let filename = "GlucoseDirect.sqlite"
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        return documentDirectory.appendingPathComponent(filename)
    }()

    func deleteDatabase() {
        do {
            try FileManager.default.removeItem(at: databaseURL)
        } catch _ {}
    }
}

// MARK: - SensorGlucose + FetchableRecord, PersistableRecord

extension SensorGlucose: FetchableRecord, PersistableRecord {
    static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    static var Table: String {
        "SensorGlucose"
    }

    enum Columns: String, ColumnExpression {
        case id
        case timestamp
        case minuteChange
        case rawGlucoseValue
        case intGlucoseValue
        case smoothGlucoseValue
        case timegroup
    }
}

// MARK: - BloodGlucose + FetchableRecord, PersistableRecord

extension BloodGlucose: FetchableRecord, PersistableRecord {
    static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    static var Table: String {
        "BloodGlucose"
    }

    enum Columns: String, ColumnExpression {
        case id
        case timestamp
        case glucoseValue
        case timegroup
    }
}

// MARK: - SensorError + FetchableRecord, PersistableRecord

extension SensorError: FetchableRecord, PersistableRecord {
    static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    static var Table: String {
        "SensorError"
    }

    enum Columns: String, ColumnExpression {
        case id
        case timestamp
        case error
        case timegroup
    }
}
