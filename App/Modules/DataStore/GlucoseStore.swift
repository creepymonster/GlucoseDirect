//
//  GlucoseStore.swift
//  GlucoseDirectApp
//
//  https://github.com/groue/GRDB.swift
//

import Combine
import Foundation
import GRDB

func glucoseStoreMiddleware() -> Middleware<DirectState, DirectAction> {
    return { _, action, _ in
        switch action {
        case .startup:
            DataStore.shared.createGlucoseTable()

            return Just(.setGlucoseValues(glucoseValues: DataStore.shared.getGlucose()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        case .addGlucose(glucoseValues: let glucoseValues):
            DataStore.shared.insertGlucose(glucoseValues)

            return Just(.setGlucoseValues(glucoseValues: DataStore.shared.getGlucose()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        case .deleteGlucose(glucose: let glucose):
            DataStore.shared.deleteGlucose(glucose)

            return Just(.setGlucoseValues(glucoseValues: DataStore.shared.getGlucose()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()
            
        case .clearGlucoseValues:
            DataStore.shared.deleteAllGlucose()
            
            return Just(.setGlucoseValues(glucoseValues: []))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - StoredGlucose

struct StoredGlucose: Codable, FetchableRecord, PersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case timestamp
        case minuteChange
        case rawGlucoseValue
        case rawType
        case intGlucoseValue
    }

    static var Table: String {
        "StoredGlucose"
    }

    var id: String
    var timestamp: Date
    var minuteChange: Double?
    var rawGlucoseValue: Int?
    var rawType: String
    var intGlucoseValue: Int?
}

extension DataStore {
    func createGlucoseTable() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    try db.create(table: StoredGlucose.Table, ifNotExists: true) { t in
                        t.autoIncrementedPrimaryKey(primaryKeyColumn)
                        t.column(StoredGlucose.Columns.id.name, .text)
                            .notNull()
                            .unique()
                            .indexed()
                        t.column(StoredGlucose.Columns.timestamp.name, .date)
                            .notNull()
                            .indexed()
                        t.column(StoredGlucose.Columns.minuteChange.name, .double)
                        t.column(StoredGlucose.Columns.rawGlucoseValue.name, .integer)
                        t.column(StoredGlucose.Columns.rawType.name, .text)
                            .notNull()
                        t.column(StoredGlucose.Columns.intGlucoseValue.name, .integer)
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func deleteAllGlucose() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    do {
                        try StoredGlucose.deleteAll(db)
                    } catch {
                        DirectLog.error(error.localizedDescription)
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func deleteGlucose(_ value: Glucose) {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    do {
                        try StoredGlucose.deleteOne(db, key: [StoredGlucose.Columns.id.name: value.id.uuidString])
                    } catch {
                        DirectLog.error(error.localizedDescription)
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func insertGlucose(_ values: [Glucose]) {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    values.forEach { value in
                        do {
                            try StoredGlucose(id: value.id.uuidString, timestamp: value.timestamp, minuteChange: value.minuteChange, rawGlucoseValue: value.rawGlucoseValue, rawType: value.type.rawValue, intGlucoseValue: value.intGlucoseValue).insert(db)
                        } catch {
                            DirectLog.error(error.localizedDescription)
                        }
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func getGlucose(limit: Int? = nil) -> [Glucose] {
        if let dbQueue = dbQueue {
            do {
                let storedGlucoseValues: [StoredGlucose] = try dbQueue.read { db in
                    try StoredGlucose
                        .order(Column(StoredGlucose.Columns.timestamp.name))
                        .fetchAll(db)
                }

                return storedGlucoseValues.map { storedGlucose in
                    Glucose(id: UUID(uuidString: storedGlucose.id)!, timestamp: storedGlucose.timestamp, rawGlucoseValue: storedGlucose.rawGlucoseValue, intGlucoseValue: storedGlucose.intGlucoseValue, minuteChange: storedGlucose.minuteChange, type: GlucoseType(rawValue: storedGlucose.rawType)!)
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }

        return []
    }
}
