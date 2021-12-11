//
//  ActionAppLog.swift
//  LibreDirect
//

import Combine
import Foundation

func actionLogMiddleware() -> Middleware<AppState, AppAction> {
    return { _, action, _ in
        AppLog.info("Triggered action: \(action)")
        
        return Empty().eraseToAnyPublisher()
    }
}
