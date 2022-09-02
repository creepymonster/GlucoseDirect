//
//  SensorGlucoseStore.swift
//  GlucoseDirectApp
//
//  https://github.com/groue/GRDB.swift
//

import Combine
import Foundation
import GRDB

func glucoseStatisticsMiddleware() -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .loadSensorGlucoseValues:
            return Just(DirectAction.loadSensorGlucoseStatistics)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .setAlarmLow(lowerLimit: _):
            return Just(DirectAction.loadSensorGlucoseStatistics)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .setAlarmHigh(upperLimit: _):
            return Just(DirectAction.loadSensorGlucoseStatistics)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .loadSensorGlucoseStatistics:
            guard state.appState == .active else {
                break
            }

            return DataStore.shared.getSensorGlucoseStatistics(lowerLimit: state.alarmLow, upperLimit: state.alarmHigh).map { statistics in
                DirectAction.setGlucoseStatistics(statistics: statistics)
            }.eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

func sensorGlucoseStoreMiddleware() -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            DataStore.shared.createSensorGlucoseTable()

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
            guard state.appState == .active || state.httpServer else {
                break
            }

            return Publishers.MergeMany(
                DataStore.shared.getSensorGlucoseValues().map { glucoseValues in
                    DirectLog.info("getSensorGlucoseValues")
                    return DirectAction.setSensorGlucoseValues(glucoseValues: glucoseValues)
                },
                DataStore.shared.getSensorGlucoseHistory().map { glucoseValues in
                    DirectLog.info("getSensorGlucoseHistory")
                    return DirectAction.setSensorGlucoseHistory(glucoseHistory: glucoseValues)
                }
            ).eraseToAnyPublisher()

        case .setAppState(appState: let appState):
            guard appState == .active else {
                break
            }

            return Just(DirectAction.loadSensorGlucoseValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

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

    func getSensorGlucoseStatistics(lowerLimit: Int, upperLimit: Int) -> Future<GlucoseStatistics, DirectError> {
        return Future { promise in
            if let dbQueue = self.dbQueue {
                dbQueue.asyncRead { asyncDB in
                    do {
                        let db = try asyncDB.get()

                        if let row = try Row.fetchOne(db, sql: """
                            SELECT
                                COUNT(sg.intGlucoseValue) AS readings,
                                IFNULL(MIN(sg.timestamp), DATETIME('now')) AS fromTimestamp,
                                IFNULL(MAX(sg.timestamp), DATETIME('now')) AS toTimestamp,
                                IFNULL(3.31 + (0.02392 * sub.avg), 0) AS gmi,
                                IFNULL(sub.avg, 0) AS avg,
                                IFNULL(100.0 / COUNT(sg.intGlucoseValue) * COUNT(CASE WHEN sg.intGlucoseValue < 80 THEN 1 END), 0) AS tbr,
                                IFNULL(100.0 / COUNT(sg.intGlucoseValue) * COUNT(CASE WHEN sg.intGlucoseValue > 160 THEN 1 END), 0) AS tar,
                                IFNULL(JULIANDAY(MAX(sg.timestamp)) - JULIANDAY(MIN(sg.timestamp)) + 1, 0) AS days,
                                IFNULL(AVG((sg.intGlucoseValue - sub.avg) * (sg.intGlucoseValue - sub.avg)), 0) as variance
                            FROM
                                SensorGlucose sg,
                                (SELECT AVG(ssg.intGlucoseValue) AS avg FROM SensorGlucose ssg WHERE ssg.timestamp >= DATE('now', '-3 months') ) AS sub
                            WHERE
                                sg.timestamp >= date('now', '-3 months')
                        """, arguments: ["low": lowerLimit, "high": upperLimit]) {
                            let statistics = GlucoseStatistics(
                                readings: row["readings"],
                                fromTimestamp: row["fromTimestamp"],
                                toTimestamp: row["toTimestamp"],
                                gmi: row["gmi"],
                                avg: row["avg"],
                                tbr: row["tbr"],
                                tar: row["tar"],
                                variance: row["variance"],
                                days: row["days"]
                            )

                            promise(.success(statistics))
                        } else {
                            promise(.failure(DirectError.withMessage("No statistics available")))
                        }
                    } catch {
                        promise(.failure(DirectError.withMessage(error.localizedDescription)))
                    }
                }
            }
        }
    }

    func getSensorGlucoseValues(upToDay: Int = 1) -> Future<[SensorGlucose], DirectError> {
        return Future { promise in
            if let dbQueue = self.dbQueue {
                dbQueue.asyncRead { asyncDB in
                    do {
                        if let upTo = Calendar.current.date(byAdding: .day, value: -upToDay, to: Date()) {
                            let db = try asyncDB.get()
                            let result = try SensorGlucose
                                .filter(Column(SensorGlucose.Columns.timestamp.name) > upTo)
                                .order(Column(SensorGlucose.Columns.timestamp.name))
                                .fetchAll(db)

                            promise(.success(result))
                        } else {
                            promise(.failure(DirectError.withMessage("Cannot get calendar dates")))
                        }
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
                        if let from = Calendar.current.date(byAdding: .day, value: -fromDay, to: Date()),
                           let upTo = Calendar.current.date(byAdding: .day, value: -upToDay, to: Date())
                        {
                            let db = try asyncDB.get()

                            let result = try SensorGlucose
                                .filter(Column(SensorGlucose.Columns.timestamp.name) <= from)
                                .filter(Column(SensorGlucose.Columns.timestamp.name) > upTo)
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
                        } else {
                            promise(.failure(DirectError.withMessage("Cannot get calendar dates")))
                        }
                    } catch {
                        promise(.failure(DirectError.withMessage(error.localizedDescription)))
                    }
                }
            }
        }
    }
}
