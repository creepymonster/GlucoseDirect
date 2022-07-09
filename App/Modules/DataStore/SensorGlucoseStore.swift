//
//  SensorGlucoseStore.swift
//  GlucoseDirectApp
//
//  https://github.com/groue/GRDB.swift
//

import Combine
import Foundation
import GRDB

func sensorGlucoseStoreMiddleware() -> Middleware<DirectState, DirectAction> {
    return { _, action, _ in
        switch action {
        case .startup:
            DataStore.shared.createSensorGlucoseTable()

            return Just(.setSensorGlucoseValues(glucoseValues: DataStore.shared.getSensorGlucose()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        case .addSensorGlucose(glucoseValues: let glucoseValues):
            DataStore.shared.insertSensorGlucose(glucoseValues)

            return Just(.setSensorGlucoseValues(glucoseValues: DataStore.shared.getSensorGlucose()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        case .deleteSensorGlucose(glucose: let glucose):
            DataStore.shared.deleteSensorGlucose(glucose)

            return Just(.setSensorGlucoseValues(glucoseValues: DataStore.shared.getSensorGlucose()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()
            
        case .clearSensorGlucoseValues:
            DataStore.shared.deleteAllSensorGlucose()
            
            return Just(.setSensorGlucoseValues(glucoseValues: []))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - StoredSensorGlucose

struct StoredSensorGlucose: Codable, FetchableRecord, PersistableRecord {
    enum Columns: String, ColumnExpression {
        case id
        case timestamp
        case minuteChange
        case rawGlucoseValue
        case intGlucoseValue
    }

    static var Table: String {
        "StoredSensorGlucose"
    }

    var id: String
    var timestamp: Date
    var minuteChange: Double?
    var rawGlucoseValue: Int
    var intGlucoseValue: Int
}

extension DataStore {
    func createSensorGlucoseTable() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    try db.create(table: StoredSensorGlucose.Table, ifNotExists: true) { t in
                        t.autoIncrementedPrimaryKey(primaryKeyColumn)
                        t.column(StoredSensorGlucose.Columns.id.name, .text)
                            .notNull()
                            .unique()
                            .indexed()
                        t.column(StoredSensorGlucose.Columns.timestamp.name, .date)
                            .notNull()
                            .indexed()
                        t.column(StoredSensorGlucose.Columns.minuteChange.name, .double)
                        t.column(StoredSensorGlucose.Columns.rawGlucoseValue.name, .integer)
                            .notNull()
                        t.column(StoredSensorGlucose.Columns.intGlucoseValue.name, .integer)
                            .notNull()
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func deleteAllSensorGlucose() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    do {
                        try StoredSensorGlucose.deleteAll(db)
                    } catch {
                        DirectLog.error(error.localizedDescription)
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func deleteSensorGlucose(_ value: SensorGlucose) {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    do {
                        try StoredSensorGlucose.deleteOne(db, key: [StoredSensorGlucose.Columns.id.name: value.id.uuidString])
                    } catch {
                        DirectLog.error(error.localizedDescription)
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func insertSensorGlucose(_ values: [SensorGlucose]) {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    values.forEach { value in
                        do {
                            try StoredSensorGlucose(id: value.id.uuidString, timestamp: value.timestamp, minuteChange: value.minuteChange, rawGlucoseValue: value.rawGlucoseValue, intGlucoseValue: value.intGlucoseValue).insert(db)
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

    func getSensorGlucose(limit: Int? = nil) -> [SensorGlucose] {
        if let dbQueue = dbQueue {
            do {
                let StoredSensorGlucoseValues: [StoredSensorGlucose] = try dbQueue.read { db in
                    try StoredSensorGlucose
                        .order(Column(StoredSensorGlucose.Columns.timestamp.name))
                        .fetchAll(db)
                }

                return StoredSensorGlucoseValues.map { StoredSensorGlucose in
                    SensorGlucose(id: UUID(uuidString: StoredSensorGlucose.id)!, timestamp: StoredSensorGlucose.timestamp, rawGlucoseValue: StoredSensorGlucose.rawGlucoseValue, intGlucoseValue: StoredSensorGlucose.intGlucoseValue, minuteChange: StoredSensorGlucose.minuteChange)
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }

        return []
    }
}
