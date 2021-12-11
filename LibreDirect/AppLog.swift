//
//  AppLog.swift
//  LibreDirect
//

import Combine
import Foundation
import OSLog

// MARK: - Log

enum AppLog {
    // MARK: Internal

    static func debug(_ message: String, log: OSLog = .default, file: String = #fileID, line: Int = #line, function: String = #function) {
        self.log(message: message, type: .debug, log: log, error: nil, file: file, line: line, function: function)
    }

    static func info(_ message: String, log: OSLog = .default, file: String = #fileID, line: Int = #line, function: String = #function) {
        self.log(message: message, type: .info, log: log, error: nil, file: file, line: line, function: function)
    }

    static func warning(_ message: String, log: OSLog = .default, file: String = #fileID, line: Int = #line, function: String = #function) {
        self.log(message: message, type: .default, log: log, error: nil, file: file, line: line, function: function)
    }

    static func error(_ message: String, log: OSLog = .default, error: Error? = nil, file: String = #fileID, line: Int = #line, function: String = #function) {
        self.log(message: message, type: .error, log: log, error: error, file: file, line: line, function: function)
    }

    //
    static func getLogEntries(hours: Double = 24, completionHandler: @escaping (_ enties: [OSLogEntryLog]) -> Void) {
        DispatchQueue.global(qos: .default).async {
            do {
                let logEntries = try readLogEntries(hours: hours)

                DispatchQueue.main.async {
                    completionHandler(logEntries)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler([])
                }
            }
        }
    }

    // MARK: Private

    private static var subsystem = Bundle.main.bundleIdentifier!

    private static let logger = {
        Logger(subsystem: subsystem, category: "main")
    }()

    private static func readLogEntries(hours: Double) throws -> [OSLogEntryLog] {
        let logStore = try OSLogStore(scope: .currentProcessIdentifier)
        let oneHourAgo = logStore.position(date: Date().addingTimeInterval(-3600 * hours))
        let allEntries = try logStore.getEntries(at: oneHourAgo)

        // FB8518539: Using NSPredicate to filter the subsystem doesn't seem to work.
        return allEntries
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.subsystem == subsystem }
    }

    private static func log(message: String, type: OSLogType, log: OSLog, error: Error?, file: String, line: Int, function: String) {
        // Console logging
        let meta: String = "[\(file):\(line)] [\(function)]"

        if let error = error {
            logger.log(level: type, "\(meta) \(message) \(error.localizedDescription)")
        } else {
            logger.log(level: type, "\(meta) \(message)")
        }
    }
}
