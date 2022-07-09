//
//  BloodGlucoseStore.swift
//  GlucoseDirectApp
//
//  https://github.com/groue/GRDB.swift
//

import Combine
import Foundation
import GRDB

func bloodGlucoseStoreMiddleware() -> Middleware<DirectState, DirectAction> {
    return { _, action, _ in
        switch action {
        case .startup:
            DataStore.shared.createBloodGlucoseTable()

            return Just(.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        case .addBloodGlucose(glucoseValues: let glucoseValues):
            DataStore.shared.insertBloodGlucose(glucoseValues)

            return Just(.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        case .deleteBloodGlucose(glucose: let glucose):
            DataStore.shared.deleteBloodGlucose(glucose)

            return Just(.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        case .clearBloodGlucoseValues:
            DataStore.shared.deleteAllBloodGlucose()

            return Just(.setBloodGlucoseValues(glucoseValues: []))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - StoredBloodGlucose

struct StoredBloodGlucose: Codable, FetchableRecord, PersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case timestamp
        case glucoseValue
    }

    static var Table: String {
        "StoredBloodGlucose"
    }

    var id: String
    var timestamp: Date
    var glucoseValue: Int
}

extension DataStore {
    func createBloodGlucoseTable() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    try db.create(table: StoredBloodGlucose.Table, ifNotExists: true) { t in
                        t.autoIncrementedPrimaryKey(primaryKeyColumn)
                        t.column(StoredBloodGlucose.Columns.id.name, .text)
                            .notNull()
                            .unique()
                            .indexed()
                        t.column(StoredBloodGlucose.Columns.timestamp.name, .date)
                            .notNull()
                            .indexed()
                        t.column(StoredBloodGlucose.Columns.glucoseValue.name, .integer)
                            .notNull()
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func deleteAllBloodGlucose() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    do {
                        try StoredBloodGlucose.deleteAll(db)
                    } catch {
                        DirectLog.error(error.localizedDescription)
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func deleteBloodGlucose(_ value: BloodGlucose) {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    do {
                        try StoredBloodGlucose.deleteOne(db, key: [StoredBloodGlucose.Columns.id.name: value.id.uuidString])
                    } catch {
                        DirectLog.error(error.localizedDescription)
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func insertBloodGlucose(_ values: [BloodGlucose]) {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    values.forEach { value in
                        do {
                            try StoredBloodGlucose(id: value.id.uuidString, timestamp: value.timestamp, glucoseValue: value.glucoseValue).insert(db)
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

    func getBloodGlucose(limit: Int? = nil) -> [BloodGlucose] {
        if let dbQueue = dbQueue {
            do {
                let StoredBloodGlucoseValues: [StoredBloodGlucose] = try dbQueue.read { db in
                    try StoredBloodGlucose
                        .order(Column(StoredBloodGlucose.Columns.timestamp.name))
                        .fetchAll(db)
                }

                return StoredBloodGlucoseValues.map { StoredBloodGlucose in
                    BloodGlucose(id: UUID(uuidString: StoredBloodGlucose.id)!, timestamp: StoredBloodGlucose.timestamp, glucoseValue: StoredBloodGlucose.glucoseValue)
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }

        return []
    }
}
