//
//  SensorErrorStore.swift
//  GlucoseDirect
//

import Combine
import Foundation
import GRDB

func sensorErrorStoreMiddleware() -> Middleware<DirectState, DirectAction> {
    return { _, action, _ in
        switch action {
        case .startup:
            DataStore.shared.createSensorErrorTable()

            return Just(.setSensorErrorValues(errorValues: DataStore.shared.getSensorError()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        case .addSensorError(errorValues: let errorValues):
            DataStore.shared.insertSensorError(errorValues)

            return Just(.setSensorErrorValues(errorValues: DataStore.shared.getSensorError()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        case .deleteSensorError(error: let error):
            DataStore.shared.deleteSensorError(error)

            return Just(.setSensorErrorValues(errorValues: DataStore.shared.getSensorError()))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        case .clearSensorErrorValues:
            DataStore.shared.deleteAllSensorError()

            return Just(.setSensorErrorValues(errorValues: []))
                .setFailureType(to: AppError.self)
                .eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SensorError + FetchableRecord, PersistableRecord

extension SensorError: FetchableRecord, PersistableRecord {
    static var Table: String {
        "SensorError"
    }

    enum Columns: String, ColumnExpression {
        case id
        case timestamp
        case error
    }
}

extension DataStore {
    func createSensorErrorTable() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    try db.create(table: SensorError.Table, ifNotExists: true) { t in
                        t.column(SensorError.Columns.id.name, .blob)
                            .primaryKey()
                        t.column(SensorError.Columns.timestamp.name, .date)
                            .notNull()
                            .indexed()
                        t.column(SensorError.Columns.error.name, .integer)
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func deleteAllSensorError() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    do {
                        try SensorError.deleteAll(db)
                    } catch {
                        DirectLog.error(error.localizedDescription)
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func deleteSensorError(_ value: SensorError) {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    do {
                        try SensorError.deleteOne(db, id: value.id)
                    } catch {
                        DirectLog.error(error.localizedDescription)
                    }
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }
    }

    func insertSensorError(_ values: [SensorError]) {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    values.forEach { value in
                        do {
                            try value.insert(db)
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

    func getSensorError(limit: Int? = nil) -> [SensorError] {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try SensorError
                        .filter(Column(SensorError.Columns.timestamp.name) > Calendar.current.date(byAdding: .day, value: -3, to: Date())!)
                        .order(Column(SensorError.Columns.timestamp.name))
                        .fetchAll(db)
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }

        return []
    }
}
