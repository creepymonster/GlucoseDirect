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

        case .loadSensorErrorValues:
            guard state.appState == .active else {
                break
            }

            return DataStore.shared.getSensorErrorValues().map { errorValues in
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

    func getSensorErrorValues(upToDay: Int? = 1) -> Future<[SensorError], DirectError> {
        return Future { promise in
            if let dbQueue = self.dbQueue {
                dbQueue.asyncRead { asyncDB in
                    do {
                        if let upToDay = upToDay,
                           let upTo = Calendar.current.date(byAdding: .day, value: -upToDay, to: Date())
                        {
                            let db = try asyncDB.get()
                            let result = try SensorError
                                .filter(Column(SensorError.Columns.timestamp.name) > upTo)
                                .order(Column(SensorError.Columns.timestamp.name))
                                .fetchAll(db)

                            promise(.success(result))
                        } else {
                            let db = try asyncDB.get()
                            let result = try SensorError
                                .order(Column(SensorError.Columns.timestamp.name))
                                .fetchAll(db)

                            promise(.success(result))
                        }
                    } catch {
                        promise(.failure(DirectError.withMessage(error.localizedDescription)))
                    }
                }
            }
        }
    }
}
