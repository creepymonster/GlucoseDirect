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
        case .exportValues(values: let values):
            do {
                let fileManager = FileManager.default
                
                let temporaryDirectory = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: fileManager.temporaryDirectory, create: true)
                let temporaryURL = temporaryDirectory.appendingPathComponent("\(UUID().uuidString).csv")
                
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
            let deviceHeader = "Gerät"
            let serialHeader = "Seriennummer"
            let timestampHeader = "Gerätezeitstempel"
            let typeHeader = "Aufzeichnungstyp"
            let glucoseHeader = "Glukosewert-Verlauf mg/dL"
            let header = [deviceHeader, serialHeader, timestampHeader, typeHeader, glucoseHeader]
            
            var values = [
                header
            ]
            
            let glucoseValues = DataStore.shared.getSensorGlucoseValues()
            
            glucoseValues.forEach { value in
                values.append([
                    "Glucose Direct",
                    state.appSerial,
                    value.timestamp.toISOStringFromDate(),
                    "0",
                    value.glucoseValue.description
                ])
            }
            
            return Just(DirectAction.exportValues(values: values))
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

private extension DataStore {
    func getSensorGlucoseValues() -> [SensorGlucose] {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try SensorGlucose
                        .order(Column(SensorGlucose.Columns.timestamp.name))
                        .fetchAll(db)
                }
            } catch {}
        }
        
        return []
    }
}

private extension FileHandle {
    func writeRow(items: [String]) {
        let line = items.joined(separator: ",")
        write("\(line)\n".data(using: .utf8)!)
    }
}
