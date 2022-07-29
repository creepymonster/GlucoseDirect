//
//  DataStore.swift
//  GlucoseDirectApp
//
//  https://github.com/groue/GRDB.swift
//

import Combine
import Foundation
import GRDB

// MARK: - DataStore

class DataStore {
    // MARK: Lifecycle

    private init() {
        do {
            dbQueue = try DatabaseQueue(path: databaseURL.absoluteString)
        } catch {
            DirectLog.error(error.localizedDescription)
            dbQueue = nil
        }
    }

    deinit {
        do {
            try dbQueue?.close()
        } catch {
            DirectLog.error(error.localizedDescription)
        }
    }

    // MARK: Internal

    static let shared = DataStore()

    let dbQueue: DatabaseQueue?

    var databaseURL: URL = {
        let filename = "GlucoseDirect.sqlite"
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        return documentDirectory.appendingPathComponent(filename)
    }()

    func deleteDatabase() {
        do {
            try FileManager.default.removeItem(at: databaseURL)
        } catch _ {}
    }
}
