//
//  SensorConnectionInfo.swift
//  GlucoseDirect
//

import Combine
import Foundation

typealias SensorConnectionCreator = (PassthroughSubject<DirectAction, AppError>) -> SensorConnectionProtocol

// MARK: - SensorConnectionInfo

class SensorConnectionInfo: Identifiable {
    // MARK: Lifecycle

    init(id: String, name: String, connectionCreator: @escaping SensorConnectionCreator) {
        self.id = id
        self.name = name
        self.connectionCreator = connectionCreator
    }

    // MARK: Internal

    let id: String
    let name: String
    let connectionCreator: SensorConnectionCreator
}
