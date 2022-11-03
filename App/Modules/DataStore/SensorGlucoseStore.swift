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

        case .setStatisticsDays(days: _):
            return Just(DirectAction.loadSensorGlucoseStatistics)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .loadSensorGlucoseStatistics:
            guard state.appState == .active else {
                break
            }

            return DataStore.shared.getSensorGlucoseStatistics(days: state.statisticsDays, lowerLimit: state.alarmLow, upperLimit: state.alarmHigh).map { statistics in
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
            
            return DataStore.shared.getFirstSensorGlucoseDate().map { minSelectedDate in
                DirectAction.setMinSelectedDate(minSelectedDate: minSelectedDate)
            }.eraseToAnyPublisher()

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

        case .setSelectedDate(selectedDate: _):
            return Just(DirectAction.loadSensorGlucoseValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .loadSensorGlucoseValues:
            guard state.appState == .active else {
                break
            }

            return DataStore.shared.getSensorGlucoseValues(selectedDate: state.selectedDate).map { glucoseValues in
                DirectAction.setSensorGlucoseValues(glucoseValues: glucoseValues)
            }.eraseToAnyPublisher()

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

private extension DataStore {
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
                DirectLog.error("\(error)")
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
                        DirectLog.error("\(error)")
                    }
                }
            } catch {
                DirectLog.error("\(error)")
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
                        DirectLog.error("\(error)")
                    }
                }
            } catch {
                DirectLog.error("\(error)")
            }
        }
    }

    func insertSensorGlucose(_ values: [SensorGlucose]) {
        if let dbQueue = dbQueue {
            do {
                try values.forEach { value in
                    try dbQueue.write { db in
                        let count = try SensorGlucose
                            .filter(Column(SensorGlucose.Columns.timestamp.name) == value.timestamp)
                            .fetchCount(db)

                        if count == 0 {
                            try value.insert(db)
                        }
                    }
                }
            } catch {
                DirectLog.error("\(error)")
            }
        }
    }

    func getSensorGlucoseStatistics(days: Int, lowerLimit: Int, upperLimit: Int) -> Future<GlucoseStatistics, DirectError> {
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
                                IFNULL(100.0 / COUNT(sg.intGlucoseValue) * COUNT(CASE WHEN sg.intGlucoseValue < :low THEN 1 END), 0) AS tbr,
                                IFNULL(100.0 / COUNT(sg.intGlucoseValue) * COUNT(CASE WHEN sg.intGlucoseValue > :high THEN 1 END), 0) AS tar,
                                IFNULL(JULIANDAY(MAX(sg.timestamp)) - JULIANDAY(MIN(sg.timestamp)) + 1, 0) AS days,
                                IFNULL(AVG((sg.intGlucoseValue - sub.avg) * (sg.intGlucoseValue - sub.avg)), 0) as variance
                            FROM
                                SensorGlucose sg, (
                                    SELECT AVG(ssg.intGlucoseValue) AS avg
                                    FROM SensorGlucose ssg
                                    WHERE ssg.timestamp >= DATETIME('now', 'start of day', :days) AND ssg.timestamp <= DATETIME('now', 'start of day')
                                ) AS sub
                            WHERE
                                sg.timestamp >= DATETIME('now', 'start of day', :days) and sg.timestamp < DATETIME('now', 'start of day')
                        """, arguments: ["days": "-\(days) days", "low": lowerLimit, "high": upperLimit]) {
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
                            promise(.failure(.withMessage("No statistics available")))
                        }
                    } catch {
                        promise(.failure(.withMessage(error.localizedDescription)))
                    }
                }
            }
        }
    }
    
    func getFirstSensorGlucoseDate() -> Future<Date, DirectError> {
        return Future { promise in
            if let dbQueue = self.dbQueue {
                dbQueue.asyncRead { asyncDB in
                    do {
                        let db = try asyncDB.get()
                        
                        if let date = try Date.fetchOne(db, sql: "SELECT MIN(timestamp) FROM SensorGlucose") {
                            promise(.success(date))
                        } else {
                            promise(.success(Date()))
                        }
                    } catch {
                        promise(.failure(.withMessage(error.localizedDescription)))
                    }
                }
            }
        }
    }

    func getSensorGlucoseValues(selectedDate: Date? = nil) -> Future<[SensorGlucose], DirectError> {
        return Future { promise in
            if let dbQueue = self.dbQueue {
                dbQueue.asyncRead { asyncDB in
                    do {
                        let db = try asyncDB.get()
                        
                        if let selectedDate = selectedDate, let nextDate = Calendar.current.date(byAdding: .day, value: +1, to: selectedDate) {
                            let result = try SensorGlucose
                                .filter(Column(SensorGlucose.Columns.timestamp.name) >= selectedDate.startOfDay)
                                .filter(nextDate.startOfDay > Column(SensorGlucose.Columns.timestamp.name))
                                .order(Column(SensorGlucose.Columns.timestamp.name))
                                .fetchAll(db)

                            promise(.success(result))
                        } else {
                            let result = try SensorGlucose
                                .filter(sql: "\(SensorGlucose.Columns.timestamp.name) >= datetime('now', '-\(DirectConfig.lastChartHours) hours')")
                                .order(Column(SensorGlucose.Columns.timestamp.name))
                                .fetchAll(db)

                            promise(.success(result))
                        }
                    } catch {
                        promise(.failure(.withMessage(error.localizedDescription)))
                    }
                }
            }
        }
    }
}
