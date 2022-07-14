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

            return Just(DirectAction.loadSensorGlucoseValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .addSensorGlucose(glucoseValues: let glucoseValues):
            guard !glucoseValues.isEmpty else {
                break
            }

            DataStore.shared.insertSensorGlucose(glucoseValues)

            return Just(DirectAction.loadSensorGlucoseValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .deleteSensorGlucose(glucose: let glucose):
            DataStore.shared.deleteSensorGlucose(glucose)

            return Just(DirectAction.loadSensorGlucoseValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .clearSensorGlucoseValues:
            DataStore.shared.deleteAllSensorGlucose()

            return Just(DirectAction.loadSensorGlucoseValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .loadSensorGlucoseValues:
            return Publishers.MergeMany(
                DataStore.shared.setSensorGlucoseValues().map { glucoseValues in
                    DirectLog.info("setSensorGlucoseValues")
                    return DirectAction.setSensorGlucoseValues(glucoseValues: glucoseValues)
                },
                DataStore.shared.getSensorGlucoseHistory().map { glucoseValues in
                    DirectLog.info("getSensorGlucoseHistory")
                    return DirectAction.setSensorGlucoseHistory(glucoseHistory: glucoseValues)
                }
            ).eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
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
        case timegroup
    }
}

extension DataStore {
    func createSensorGlucoseTable() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    try db.create(table: SensorGlucose.Table, ifNotExists: true) { t in
                        t.column(SensorGlucose.Columns.id.name, .text)
                            .primaryKey()
                        t.column(SensorGlucose.Columns.timestamp.name, .date)
                            .notNull()
                            .indexed()
                        t.column(SensorGlucose.Columns.minuteChange.name, .double)
                        t.column(SensorGlucose.Columns.rawGlucoseValue.name, .integer)
                            .notNull()
                        t.column(SensorGlucose.Columns.intGlucoseValue.name, .integer)
                            .notNull()
                        t.column(SensorGlucose.Columns.timegroup.name, .date)
                            .notNull()
                            .indexed()
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
                        try SensorGlucose.deleteAll(db)
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
                        try SensorGlucose.deleteOne(db, id: value.id)
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

    func setSensorGlucoseValues(upToDay: Int = 1) -> Future<[SensorGlucose], DirectError> {
        return Future { promise in
            if let dbQueue = self.dbQueue {
                dbQueue.asyncRead { asyncDB in
                    do {
                        let db = try asyncDB.get()
                        let result = try SensorGlucose
                            .filter(Column(SensorGlucose.Columns.timestamp.name) > Calendar.current.date(byAdding: .day, value: -upToDay, to: Date())!)
                            .order(Column(SensorGlucose.Columns.timestamp.name))
                            .fetchAll(db)

                        promise(.success(result))
                    } catch {
                        promise(.failure(DirectError.withMessage(error.localizedDescription)))
                    }
                }
            }
        }
    }

    func getSensorGlucoseHistory(fromDay: Int = 1, upToDay: Int = 7) -> Future<[SensorGlucose], DirectError> {
        return Future { promise in
            if let dbQueue = self.dbQueue {
                dbQueue.asyncRead { asyncDB in
                    do {
                        let db = try asyncDB.get()
                        let result = try SensorGlucose
                            .filter(Column(SensorGlucose.Columns.timestamp.name) <= Calendar.current.date(byAdding: .day, value: -fromDay, to: Date())!)
                            .filter(Column(SensorGlucose.Columns.timestamp.name) > Calendar.current.date(byAdding: .day, value: -upToDay, to: Date())!)
                            .select(
                                min(SensorGlucose.Columns.id).forKey(SensorGlucose.Columns.id.name),
                                SensorGlucose.Columns.timegroup.forKey(SensorGlucose.Columns.timestamp.name),
                                sum(SensorGlucose.Columns.minuteChange).forKey(SensorGlucose.Columns.minuteChange.name),
                                average(SensorGlucose.Columns.rawGlucoseValue).forKey(SensorGlucose.Columns.rawGlucoseValue.name),
                                average(SensorGlucose.Columns.intGlucoseValue).forKey(SensorGlucose.Columns.intGlucoseValue.name),
                                SensorGlucose.Columns.timegroup
                            )
                            .group(SensorGlucose.Columns.timegroup)
                            .order(Column(SensorGlucose.Columns.timestamp.name))
                            .fetchAll(db)

                        promise(.success(result))
                    } catch {
                        promise(.failure(DirectError.withMessage(error.localizedDescription)))
                    }
                }
            }
        }
    }
}
