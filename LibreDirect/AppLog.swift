//
//  AppLog.swift
//  LibreDirect
//

import Combine
import Foundation
import OSLog

// MARK: - AppLog

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

    static func deleteLogs() {
        fileLogger.deleteLogs()
    }

    static func getLogfileUrl() -> URL {
        return fileLogger.allLogsFileURL
    }

    // MARK: Private

    private static let fileLogger: FileLogger = {
        FileLogger()
    }()

    private static func log(message: String, type: OSLogType, log: OSLog, error: Error?, file: String, line: Int, function: String) {
        // Console logging
        let meta: String = "[\(file):\(line)]" // [\(function)]

        // obviously we have to disable swiftline here:
        // swiftlint:disable:next no_direct_oslog
        os_log("%{public}@ %{public}@", log: log, type: type, meta, message)

        // Save logs to File. This is used for viewing and exporting logs from debug menu.
        fileLogger.log(message, logType: type, file: file, line: line, function: function)
    }
}

extension OSLogType {
    var title: String {
        switch self {
        case .error:
            return "Error"
        case .debug:
            return "Debug"
        case .info:
            return "Info"
        case .default:
            return "Warning"
        default:
            return "Other"
        }
    }

    var icon: String {
        switch self {
        case .error:
            return "❌"
        case .debug:
            return "🛠"
        case .info:
            return "ℹ️"
        case .default:
            return "⚠️"
        default:
            return ""
        }
    }

    var logFilePath: String {
        return "\(title).log"
    }
}

// MARK: - FileLogger

struct FileLogger {
    // MARK: Internal

    enum Error: Swift.Error {
        case streamerInitError
    }

    /// The directory where all logs are stored
    let logFileBaseURL: URL = {
        let fileManager = FileManager.default
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Logs")
    }()

    let oldLogsFileURL: URL = {
        let fileManager = FileManager.default
        let baseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("GlucoseDirect.log")
    }()

    /// Path to a common log file for all log types combined
    let allLogsFileURL: URL = {
        let fileManager = FileManager.default
        let baseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Logs")
        return baseURL.appendingPathComponent("AllLogs.log")
    }()

    func log(_ logMessage: String, logType: OSLogType, file: String? = nil, line: Int? = nil, function: String? = nil) {
        var meta: String = ""
        if let file = file, let line = line, let function = function {
            meta = "[\(file):\(line)] [\(function)]\n"
        }
        let prefixedLogMessage = "\(logType.icon) \(logDateFormatter.string(from: Date()))\n\(meta)\(logMessage)\n\n"

        guard let fileHandle = makeWriteFileHandle(with: logType),
              let logMessageData = prefixedLogMessage.data(using: encoding)
        else {
            return
        }
        defer {
            fileHandle.closeFile()
        }

        fileHandle.seekToEndOfFile()
        fileHandle.write(logMessageData)

        guard let allLogsFileHandle = makeWriteFileHandle(with: allLogsFileURL) else {
            return
        }
        allLogsFileHandle.seekToEndOfFile()
        allLogsFileHandle.write(logMessageData)
    }

    /// `StreamReader` for a given log type
    /// - Parameter logType: the log type to read
    /// - Throws: `FileLogger.Error.streamerInitError` if Reader initialization fails
    /// - Returns: a `StreamReader`
    func logReader(for logType: OSLogType) throws -> StreamReader {
        let fileURL = logFileBaseURL.appendingPathComponent(logType.logFilePath)
        try createLogFile(for: fileURL)
        guard let reader = StreamReader(at: fileURL) else {
            throw Error.streamerInitError
        }
        return reader
    }

    /// `StreamReader` for all log types combined
    /// - Throws: `FileLogger.Error.streamerInitError` if Reader initialization fails
    /// - Returns: a `StreamReader`
    func logReader() throws -> StreamReader {
        let url = allLogsFileURL
        try createLogFile(for: url)
        guard let reader = StreamReader(at: url) else {
            throw Error.streamerInitError
        }
        return reader
    }

    func deleteLogs() {
        do {
            if FileManager.default.fileExists(atPath: oldLogsFileURL.path) {
                do {
                    try FileManager.default.removeItem(at: oldLogsFileURL)
                } catch {
                    AppLog.error("Failed to remove file: \(error.localizedDescription)")
                }
            }

            try FileManager.default.removeItem(at: logFileBaseURL)
        } catch {
            AppLog.error("Can't remove logs at \(logFileBaseURL)", log: .default, error: error)
        }
    }

    // MARK: Private

    private let encoding: String.Encoding = .utf8
    private let logDateFormatter = ISO8601DateFormatter()

    private func createLogFile(for url: URL) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: logFileBaseURL, withIntermediateDirectories: true)
            fileManager.createFile(atPath: url.path, contents: Data())
        }
    }

    private func makeWriteFileHandle(with logType: OSLogType) -> FileHandle? {
        let logFileURL = logFileBaseURL.appendingPathComponent("\(logType.title).log")
        return makeWriteFileHandle(with: logFileURL)
    }

    private func makeWriteFileHandle(with url: URL) -> FileHandle? {
        do {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: url.path) {
                try fileManager.createDirectory(at: logFileBaseURL, withIntermediateDirectories: true)
                fileManager.createFile(atPath: url.path, contents: nil)
            }

            let fileHandle = try? FileHandle(forWritingTo: url)
            return fileHandle
        } catch {
            AppLog.error("File handle error", log: .default, error: error)
            return nil
        }
    }

    private func makeReadFileHandle(with logType: OSLogType) -> FileHandle? {
        let logFileURL = logFileBaseURL.appendingPathComponent("\(logType.title).log")
        return makeReadFileHandle(with: logFileURL)
    }

    private func makeReadFileHandle(with url: URL) -> FileHandle? {
        do {
            return try FileHandle(forReadingFrom: url)
        } catch {
            AppLog.error("File handle error", log: .default, error: error)
            return nil
        }
    }
}

// MARK: - StreamReader

class StreamReader {
    // MARK: Lifecycle

    /// A StreamReader for large files. Reads them line by line.
    ///
    /// - Parameters:
    ///   - url: the url to the file to read
    ///   - delimiter: the line delimiter; defaults to `\n`
    ///   - encoding: the file encoding to expect; defaults to `.utf8`
    ///   - chunkSize: the buffer size during the read process; defaults to 4096 bytes
    init?(at url: URL, delimiter: String = "\n", encoding: String.Encoding = .utf8, chunkSize: Int = 4096) {
        do {
            let fileHandle = try FileHandle(forReadingFrom: url)
            guard
                let delimData = delimiter.data(using: encoding),
                let buffer = NSMutableData(capacity: chunkSize)
            else {
                preconditionFailure("Cannot initialize StreamReader for file at \(url)")
                return nil
            }
            self.chunkSize = chunkSize
            self.encoding = encoding
            self.fileHandle = fileHandle
            self.delimData = delimData
            self.buffer = buffer
        } catch {
            preconditionFailure(error.localizedDescription)
            return nil
        }
    }

    /// A StreamReader for large files. Reads them line by line.
    ///
    /// - Parameters:
    ///   - path: the path to the file to read
    ///   - delimiter: the line delimiter; defaults to `\n`
    ///   - encoding: the file encoding to expect; defaults to `.utf8`
    ///   - chunkSize: the buffer size during the read process; defaults to 4096 bytes
    convenience init?(at path: String, delimiter: String = "\n", encoding: String.Encoding = .utf8, chunkSize: Int = 4096) {
        guard let url = URL(string: path) else { return nil }
        self.init(at: url, delimiter: delimiter, encoding: encoding, chunkSize: chunkSize)
    }

    deinit {
        self.close()
    }

    // MARK: Internal

    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        if atEof {
            return nil
        }

        // Read data chunks from file until a line delimiter is found:
        var range = buffer.range(of: delimData, options: [], in: NSRange(location: 0, length: buffer.length))
        while range.location == NSNotFound {
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.isEmpty {
                // EOF or read error.
                atEof = true
                if buffer.length > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = String(data: buffer as Data, encoding: encoding)

                    buffer.length = 0
                    return line as String?
                }
                // No more lines.
                return nil
            }
            buffer.append(tmpData)

            range = buffer.range(of: delimData, options: [], in: NSRange(location: 0, length: buffer.length))
        }

        // Convert complete line (excluding the delimiter) to a string:
        let line = NSString(data: buffer.subdata(with: NSRange(location: 0, length: range.location)), encoding: encoding.rawValue)
        // Remove line (and the delimiter) from the buffer:
        buffer.replaceBytes(in: NSRange(location: 0, length: range.location + range.length), withBytes: nil, length: 0)

        return line as String?
    }

    /// Start reading from the beginning of file.
    func rewind() {
        fileHandle.seek(toFileOffset: 0)
        buffer.length = 0
        atEof = false
    }

    /// Close the underlying file. No reading must be done after calling this method.
    func close() {
        fileHandle.closeFile()
    }

    // MARK: Private

    private let encoding: String.Encoding
    private let chunkSize: Int
    private let buffer: NSMutableData
    private let delimData: Data

    private var fileHandle: FileHandle
    private var atEof: Bool = false
}
