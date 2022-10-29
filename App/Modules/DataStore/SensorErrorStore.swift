//
//  SensorErrorStore.swift
//  GlucoseDirect
//

import Combine
import Foundation
import GRDB

func sensorErrorStoreMiddleware() -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            DataStore.shared.createSensorErrorTable()

        case .addSensorError(errorValues: let errorValues):
            guard !errorValues.isEmpty else {
                break
            }

            DataStore.shared.insertSensorError(errorValues)

            return Just(DirectAction.loadSensorErrorValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .deleteSensorError(error: let error):
            DataStore.shared.deleteSensorError(error)

            return Just(DirectAction.loadSensorErrorValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .clearSensorErrorValues:
            DataStore.shared.deleteAllSensorError()

            return Just(DirectAction.loadSensorErrorValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()
            
        case .setSelectedDate(selectedDate: _):
            return Just(DirectAction.loadSensorErrorValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .loadSensorErrorValues:
            guard state.appState == .active else {
                break
            }

            return DataStore.shared.getSensorErrorValues(selectedDate: state.selectedDate).map { errorValues in
                DirectAction.setSensorErrorValues(errorValues: errorValues)
            }.eraseToAnyPublisher()

        case .setAppState(appState: let appState):
            guard appState == .active else {
                break
            }

            return Just(DirectAction.loadSensorErrorValues)
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

private extension DataStore {
    func createSensorErrorTable() {
        if let dbQueue = dbQueue {
            do {
                try dbQueue.write { db in
                    try db.create(table: SensorError.Table, ifNotExists: true) { t in
                        t.column(SensorError.Columns.id.name, .text)
                            .primaryKey()
                        t.column(SensorError.Columns.timestamp.name, .date)
                            .notNull()
                            .indexed()
                        t.column(SensorError.Columns.error.name, .integer)
                            .notNull()
                        t.column(SensorError.Columns.timegroup.name, .date)
                            .notNull()
                            .indexed()
                    }
                }
            } catch {
                DirectLog.error("\(error)")
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
                        DirectLog.error("\(error)")
                    }
                }
            } catch {
                DirectLog.error("\(error)")
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
                        DirectLog.error("\(error)")
                    }
                }
            } catch {
                DirectLog.error("\(error)")
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
                            DirectLog.error("\(error)")
                        }
                    }
                }
            } catch {
                DirectLog.error("\(error)")
            }
        }
    }

    func getSensorErrorValues(selectedDate: Date? = nil) -> Future<[SensorError], DirectError> {
        return Future { promise in
            if let dbQueue = self.dbQueue {
                dbQueue.asyncRead { asyncDB in
                    do {
                        let db = try asyncDB.get()
                        
                        if let selectedDate = selectedDate, let nextDate = Calendar.current.date(byAdding: .day, value: +1, to: selectedDate) {
                            let result = try SensorError
                                .filter(Column(SensorGlucose.Columns.timestamp.name) >= selectedDate.startOfDay)
                                .filter(nextDate.startOfDay > Column(SensorGlucose.Columns.timestamp.name))
                                .order(Column(SensorError.Columns.timestamp.name))
                                .fetchAll(db)

                            promise(.success(result))
                        } else {
                            let result = try SensorError
                                .filter(sql: "\(SensorError.Columns.timestamp.name) >= datetime('now', '-24 hours')")
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
