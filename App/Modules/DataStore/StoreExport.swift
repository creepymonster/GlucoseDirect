//
//  StoreExport.swift
//  GlucoseDirectApp
//

import Combine
import Foundation
import GRDB

func createFile(filename: String) -> URL? {
    do {
        let fileManager = FileManager.default
    
        let temporaryDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let temporaryURL = temporaryDirectory.appendingPathComponent("\(filename).csv")
    
        if fileManager.fileExists(atPath: temporaryURL.path) {
            try fileManager.removeItem(atPath: temporaryURL.path)
        }
    
        let createdFile = fileManager.createFile(atPath: temporaryURL.path, contents: nil, attributes: nil)
        if createdFile {
            return temporaryURL
        }
    } catch {
        DirectLog.info("Error writing csv: \(error)")
    }
    
    return nil
}

func writeFile(temporaryURL: URL, values: [[String]]) {
    do {
        let fileHandle = try FileHandle(forWritingTo: temporaryURL)
        fileHandle.seekToEndOfFile()
            
        defer {
            fileHandle.closeFile()
        }
            
        values.forEach { value in
            fileHandle.writeRow(items: value)
        }
        
        fileHandle.closeFile()
    } catch {
        DirectLog.info("Error writing csv: \(error)")
    }
}

func storeExportMiddleware() -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .exportToUnknown:
            return Future { promise in
                DispatchQueue.global().async {
                    if let fileURL = createFile(filename: "glucose-direct") {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        
                        let mmolLFormatter = NumberFormatter()
                        mmolLFormatter.numberStyle = .decimal
                        mmolLFormatter.decimalSeparator = "."
                        mmolLFormatter.minimumFractionDigits = 1
                        mmolLFormatter.maximumFractionDigits = 1
                        
                        let header = [
                            "Id",
                            "Timestamp",
                            "Glucose in mg/dL",
                            "Glucose in mmol/L"
                        ]
                        
                        let glucoseValueLimit = 1000
                        let glucoseValuePages = DataStore.shared.getSensorGlucoseValuesPages(limit: glucoseValueLimit)
                        
                        writeFile(temporaryURL: fileURL, values: [
                            header
                        ])
                        
                        for i in 0 ... glucoseValuePages {
                            let glucoseValues = DataStore.shared.getSensorGlucoseValues(offset: i * glucoseValueLimit, limit: glucoseValueLimit).map { value in
                                [
                                    value.id.uuidString,
                                    dateFormatter.string(from: value.timestamp),
                                    value.glucoseValue.description,
                                    mmolLFormatter.string(from: value.glucoseValue.asMmolL as NSNumber)!
                                ]
                            }
                            
                            writeFile(temporaryURL: fileURL, values: glucoseValues)
                        }
                        
                        promise(.success(.sendFile(fileURL: fileURL)))
                    } else {
                        promise(.failure(.withMessage("Cannot create unknown csv file")))
                    }
                }
            }.eraseToAnyPublisher()
            
        case .exportToTidepool:
            return Future { promise in
                DispatchQueue.global().async {
                    if let fileURL = createFile(filename: "tidepool") {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
                        
                        let headerPrefix = [
                            "Glukose-Werte",
                            "Erstellt am",
                            "\(dateFormatter.string(from: Date()))",
                            "Erstellt von",
                            "Glucose Direct"
                        ]
                        
                        let header = [
                            "Gerät",
                            "Seriennummer",
                            "Gerätezeitstempel",
                            "Aufzeichnungstyp",
                            "Glukosewert-Verlauf mg/dL",
                            "Glukose-Scan mg/dL"
                        ]
                        
                        let glucoseValueLimit = 1000
                        let glucoseValuePages = DataStore.shared.getSensorGlucoseHistoryPages(limit: glucoseValueLimit)
                        
                        writeFile(temporaryURL: fileURL, values: [
                            headerPrefix,
                            header
                        ])
                        
                        for i in 0 ... glucoseValuePages {
                            let glucoseValues = DataStore.shared.getSensorGlucoseHistory(offset: i * glucoseValueLimit, limit: glucoseValueLimit).map { value in
                                [
                                    "Glucose Direct",
                                    state.appSerial,
                                    dateFormatter.string(from: value.timestamp),
                                    "0",
                                    value.glucoseValue.description,
                                    value.glucoseValue.description
                                ]
                            }
                            
                            writeFile(temporaryURL: fileURL, values: glucoseValues)
                        }
                        
                        promise(.success(.sendFile(fileURL: fileURL)))
                    } else {
                        promise(.failure(.withMessage("Cannot create glooko csv file")))
                    }
                }
            }.eraseToAnyPublisher()
            
        case .exportToGlooko:
            return Future { promise in
                DispatchQueue.global().async {
                    if let fileURL = createFile(filename: "glooko") {
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
                        
                        let headerPrefix = [
                            "Glukose-Werte",
                            "Erstellt am",
                            "\(dateFormatter.string(from: Date())) UTC",
                            "Erstellt von",
                            "Glucose Direct"
                        ]
                        
                        let header = [
                            "Gerät",
                            "Seriennummer",
                            "Gerätezeitstempel",
                            "Aufzeichnungstyp",
                            "Glukosewert-Verlauf mg/dL",
                            "Glukose-Scan mg/dL"
                        ]
                        
                        let glucoseValueLimit = 1000
                        let glucoseValuePages = DataStore.shared.getSensorGlucoseHistoryPages(limit: glucoseValueLimit)
                        
                        writeFile(temporaryURL: fileURL, values: [
                            headerPrefix,
                            header
                        ])
                        
                        for i in 0 ... glucoseValuePages {
                            let glucoseValues = DataStore.shared.getSensorGlucoseHistory(offset: i * glucoseValueLimit, limit: glucoseValueLimit).map { value in
                                [
                                    "Glucose Direct",
                                    state.appSerial,
                                    dateFormatter.string(from: value.timestamp),
                                    "0",
                                    value.glucoseValue.description,
                                    value.glucoseValue.description
                                ]
                            }
                            
                            writeFile(temporaryURL: fileURL, values: glucoseValues)
                        }
                        
                        promise(.success(.sendFile(fileURL: fileURL)))
                    } else {
                        promise(.failure(.withMessage("Cannot create glooko csv file")))
                    }
                }
            }.eraseToAnyPublisher()
            
        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

private extension DataStore {
    func getSensorGlucoseValuesPages(limit: Int) -> Int {
        let count = getSensorGlucoseValuesCount()
        return Int(count / limit)
    }
    
    func getSensorGlucoseValuesCount() -> Int {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try SensorGlucose
                        .fetchCount(db)
                }
            } catch {
                DirectLog.error("\(error)")
            }
        }
        
        return 0
    }
    
    func getSensorGlucoseValues(offset: Int, limit: Int = 100) -> [SensorGlucose] {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try SensorGlucose
                        .order(Column(SensorGlucose.Columns.timestamp.name).desc)
                        .limit(limit, offset: offset)
                        .fetchAll(db)
                }
            } catch {
                DirectLog.error("\(error)")
            }
        }
        
        return []
    }
    
    func getSensorGlucoseHistoryPages(limit: Int) -> Int {
        let count = getSensorGlucoseHistoryCount()
        return Int(count / limit)
    }
    
    func getSensorGlucoseHistoryCount() -> Int {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try SensorGlucose
                        .select(SensorGlucose.Columns.timegroup)
                        .filter(sql: "\(SensorGlucose.Columns.timegroup.name) >= DATETIME('now', 'start of month', '-1 month', 'utc')")
                        .filter(sql: "\(SensorGlucose.Columns.timegroup.name) <= DATETIME('now', 'start of day', 'utc')")
                        .group(SensorGlucose.Columns.timegroup)
                        .fetchCount(db)
                }
            } catch {
                DirectLog.error("\(error)")
            }
        }
        
        return 0
    }
    
    func getSensorGlucoseHistory(offset: Int, limit: Int = 100) -> [SensorGlucose] {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try SensorGlucose
                        .select(
                            min(SensorGlucose.Columns.id).forKey(SensorGlucose.Columns.id.name),
                            SensorGlucose.Columns.timegroup.forKey(SensorGlucose.Columns.timestamp.name),
                            sum(SensorGlucose.Columns.minuteChange).forKey(SensorGlucose.Columns.minuteChange.name),
                            average(SensorGlucose.Columns.rawGlucoseValue).forKey(SensorGlucose.Columns.rawGlucoseValue.name),
                            average(SensorGlucose.Columns.intGlucoseValue).forKey(SensorGlucose.Columns.intGlucoseValue.name),
                            SensorGlucose.Columns.timegroup
                        )
                        .filter(sql: "\(SensorGlucose.Columns.timegroup.name) >= DATETIME('now', 'start of month', '-1 month', 'utc')")
                        .filter(sql: "\(SensorGlucose.Columns.timegroup.name) <= DATETIME('now', 'start of day', 'utc')")
                        .group(SensorGlucose.Columns.timegroup)
                        .order(Column(SensorGlucose.Columns.timestamp.name).desc)
                        .limit(limit, offset: offset)
                        .fetchAll(db)
                }
            } catch {
                DirectLog.error("\(error)")
            }
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
