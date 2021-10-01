//
//  ActionLog.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 19.07.21. 
//

import Foundation
import Combine

public func actionLogMiddleware() -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        Log.info("Triggered action: \(action)")

        return Empty().eraseToAnyPublisher()
    }
}
