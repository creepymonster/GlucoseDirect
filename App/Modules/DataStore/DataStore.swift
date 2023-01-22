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
            //Move the database to the app group store
            try FileManager.default.copyItem(at: oldDatabaseURL, to: containerDatabaseURL)
            try FileManager.default.removeItem(at: oldDatabaseURL)
        } catch {}
        
        do {
            dbQueue = try DatabaseQueue(path: containerDatabaseURL.absoluteString)
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
    
    var containerDatabaseURL: URL = {
        let filename = "GlucoseDirect.sqlite"
        let documentDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: UserDefaults.stringValue(forKey: "APP_GROUP_ID"))
        return documentDirectory!.appendingPathComponent(filename)
    }()

    var oldDatabaseURL: URL = {
        let filename = "GlucoseDirect.sqlite"
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentDirectory.appendingPathComponent(filename)
    }()

    func deleteDatabase() {
        do {
            try FileManager.default.removeItem(at: containerDatabaseURL)
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

// MARK: - InsulinDelivery + FetchableRecord, PersistableRecord

extension InsulinDelivery: FetchableRecord, PersistableRecord {
    static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    static var Table: String {
        "InsulinDelivery"
    }

    enum Columns: String, ColumnExpression {
        case id
        case starts
        case ends
        case units
        case type
        case timegroup
    }
}
