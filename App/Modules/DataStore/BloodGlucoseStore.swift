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

            return Publishers.MergeMany(
                Just(DirectAction.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose())),
                Just(DirectAction.setBloodGlucoseHistory(glucoseHistory: DataStore.shared.getBloodGlucoseHistory()))
            )
            .setFailureType(to: DirectError.self)
            .eraseToAnyPublisher()

//            return Just(DirectAction.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose()))
//                .merge(with: Just(DirectAction.setBloodGlucoseHistory(glucoseHistory: DataStore.shared.getBloodGlucoseHistory())))
//                .setFailureType(to: DirectError.self)
//                .eraseToAnyPublisher()

//            return Just(.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose()))
//                .setFailureType(to: AppError.self)
//                .eraseToAnyPublisher()

        case .addBloodGlucose(glucoseValues: let glucoseValues):
            guard !glucoseValues.isEmpty else {
                break
            }

            DataStore.shared.insertBloodGlucose(glucoseValues)

            return Publishers.MergeMany(
                Just(DirectAction.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose())),
                Just(DirectAction.setBloodGlucoseHistory(glucoseHistory: DataStore.shared.getBloodGlucoseHistory()))
            )
            .setFailureType(to: DirectError.self)
            .eraseToAnyPublisher()

//            return Just(DirectAction.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose()))
//                .merge(with: Just(DirectAction.setBloodGlucoseHistory(glucoseHistory: DataStore.shared.getBloodGlucoseHistory())))
//                .setFailureType(to: DirectError.self)
//                .eraseToAnyPublisher()

//            return Just(.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose()))
//                .setFailureType(to: AppError.self)
//                .eraseToAnyPublisher()

        case .deleteBloodGlucose(glucose: let glucose):
            DataStore.shared.deleteBloodGlucose(glucose)

            return Publishers.MergeMany(
                Just(DirectAction.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose())),
                Just(DirectAction.setBloodGlucoseHistory(glucoseHistory: DataStore.shared.getBloodGlucoseHistory()))
            )
            .setFailureType(to: DirectError.self)
            .eraseToAnyPublisher()

//            return Just(DirectAction.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose()))
//                .merge(with: Just(DirectAction.setBloodGlucoseHistory(glucoseHistory: DataStore.shared.getBloodGlucoseHistory())))
//                .setFailureType(to: DirectError.self)
//                .eraseToAnyPublisher()

//            return Just(.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose()))
//                .setFailureType(to: AppError.self)
//                .eraseToAnyPublisher()

        case .clearBloodGlucoseValues:
            DataStore.shared.deleteAllBloodGlucose()

            return Publishers.MergeMany(
                Just(DirectAction.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose())),
                Just(DirectAction.setBloodGlucoseHistory(glucoseHistory: DataStore.shared.getBloodGlucoseHistory()))
            )
            .setFailureType(to: DirectError.self)
            .eraseToAnyPublisher()

//            return Just(DirectAction.setBloodGlucoseValues(glucoseValues: DataStore.shared.getBloodGlucose()))
//                .merge(with: Just(DirectAction.setBloodGlucoseHistory(glucoseHistory: DataStore.shared.getBloodGlucoseHistory())))
//                .setFailureType(to: DirectError.self)
//                .eraseToAnyPublisher()

//            return Just(.setBloodGlucoseValues(glucoseValues: []))
//                .setFailureType(to: AppError.self)
//                .eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
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

extension DataStore {
    func createBloodGlucoseTable() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    try db.create(table: BloodGlucose.Table, ifNotExists: true) { t in
                        t.column(BloodGlucose.Columns.id.name, .text)
                            .primaryKey()
                        t.column(BloodGlucose.Columns.timestamp.name, .date)
                            .notNull()
                            .indexed()
                        t.column(BloodGlucose.Columns.glucoseValue.name, .integer)
                            .notNull()
                        t.column(BloodGlucose.Columns.timegroup.name, .date)
                            .notNull()
                            .indexed()
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
                        try BloodGlucose.deleteAll(db)
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
                        try BloodGlucose.deleteOne(db, id: value.id)
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

    func getBloodGlucose(upToDay: Int = 1) -> [BloodGlucose] {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try BloodGlucose
                        .filter(Column(BloodGlucose.Columns.timestamp.name) > Calendar.current.date(byAdding: .day, value: -upToDay, to: Date())!)
                        .order(Column(BloodGlucose.Columns.timestamp.name))
                        .fetchAll(db)
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }

        return []
    }

    func getBloodGlucoseHistory(fromDay: Int = 1, upToDay: Int = 7) -> [BloodGlucose] {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try BloodGlucose
                        .filter(Column(BloodGlucose.Columns.timestamp.name) <= Calendar.current.date(byAdding: .day, value: -fromDay, to: Date())!)
                        .filter(Column(BloodGlucose.Columns.timestamp.name) > Calendar.current.date(byAdding: .day, value: -upToDay, to: Date())!)
                        .select(
                            min(BloodGlucose.Columns.id).forKey(BloodGlucose.Columns.id.name),
                            BloodGlucose.Columns.timegroup.forKey(BloodGlucose.Columns.timestamp.name),
                            average(BloodGlucose.Columns.glucoseValue).forKey(BloodGlucose.Columns.glucoseValue.name),
                            BloodGlucose.Columns.timegroup
                        )
                        .group(BloodGlucose.Columns.timegroup)
                        .order(Column(BloodGlucose.Columns.timestamp.name))
                        .fetchAll(db)
                }
            } catch {
                DirectLog.error(error.localizedDescription)
            }
        }

        return []
    }
}
