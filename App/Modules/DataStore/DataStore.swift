//
//  DataStore.swift
//  GlucoseDirectApp
//
//  https://github.com/groue/GRDB.swift
//

import Combine
import Foundation
import GRDB

class DataStore {
    // MARK: Lifecycle

    private init() {
        let filename = "GlucoseDirect.sqlite"
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = documentDirectory.appendingPathComponent(filename)

//        do {
//            try FileManager.default.removeItem(at: path)
//        } catch _ {
//        }

        do {
            dbQueue = try DatabaseQueue(path: path.absoluteString)
        } catch {
            DirectLog.error(error.localizedDescription)
            dbQueue = nil
        }
    }

    // MARK: Internal

    static let shared = DataStore()
    let dbQueue: DatabaseQueue?
}
