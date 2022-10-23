//
//  StoreExport.swift
//  GlucoseDirectApp
//

import Combine
import Foundation
import GRDB

func storeExportMiddleware() -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .sendCSVFile(filename: let filename, values: let values):
            do {
                let fileManager = FileManager.default
                
                let temporaryDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let temporaryURL = temporaryDirectory.appendingPathComponent("\(filename).csv")
                
                if fileManager.fileExists(atPath: temporaryURL.path) {
                    try fileManager.removeItem(atPath: temporaryURL.path)
                }
                
                let createdFile = fileManager.createFile(atPath: temporaryURL.path, contents: nil, attributes: nil)
                if !createdFile {
                    break
                }
                
                let fileHandle = try FileHandle(forWritingTo: temporaryURL)
                
                defer {
                    fileHandle.closeFile()
                }
                
                values.forEach { value in
                    fileHandle.writeRow(items: value)
                }
                
                fileHandle.closeFile()
                
                return Publishers.MergeMany([
                    Just(DirectAction.setAppIsBusy(isBusy: false)),
                    Just(DirectAction.sendFile(fileURL: temporaryURL))
                ])
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()
            } catch {
                DirectLog.info("Error writing csv: \(error)")
                
                return Just(DirectAction.setAppIsBusy(isBusy: false))
                    .setFailureType(to: DirectError.self)
                    .eraseToAnyPublisher()
            }

        case .exportSensorGlucoseValues:
            return DataStore.shared.getSensorGlucoseValues(upToDay: 90).map { glucoseValues in
                let deviceHeader = "Gerät"
                let serialHeader = "Seriennummer"
                let timestampHeader = "Gerätezeitstempel"
                let typeHeader = "Aufzeichnungstyp"
                let glucoseHeader = "Glukosewert-Verlauf mg/dL"
                let header = [deviceHeader, serialHeader, timestampHeader, typeHeader, glucoseHeader]
                
                var values = [
                    header
                ]
                
                glucoseValues.forEach { value in
                    values.append([
                        "Glucose Direct",
                        state.appSerial,
                        value.timestamp.toISOStringFromDate(),
                        "0",
                        value.glucoseValue.description
                    ])
                }
                
                return DirectAction.sendCSVFile(filename: "glooko", values: values)
            }.eraseToAnyPublisher()
            
        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

private extension DataStore {
    func getSensorGlucoseValues(upToDay: Int? = 30) -> Future<[SensorGlucose], DirectError> {
        return Future { promise in
            if let dbQueue = self.dbQueue {
                dbQueue.asyncRead { asyncDB in
                    do {
                        if let upToDay = upToDay,
                           let upTo = Calendar.current.date(byAdding: .day, value: -upToDay, to: Date())
                        {
                            let db = try asyncDB.get()
                            let result = try SensorGlucose
                                .filter(Column(SensorGlucose.Columns.timestamp.name) > upTo)
                                .order(Column(SensorGlucose.Columns.timestamp.name))
                                .fetchAll(db)

                            promise(.success(result))
                        } else {
                            let db = try asyncDB.get()
                            let result = try SensorGlucose
                                .order(Column(SensorGlucose.Columns.timestamp.name))
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

private extension FileHandle {
    func writeRow(items: [String]) {
        let line = items.joined(separator: ",")
        write("\(line)\n".data(using: .utf8)!)
    }
}
