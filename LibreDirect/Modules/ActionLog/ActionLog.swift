//
//  ActionLog.swift
//  LibreDirect
//

import Combine
import Foundation

func actionLogMiddleware() -> Middleware<AppState, AppAction> {
    return { _, action, _ in
        Log.info("Triggered action: \(action)")
        
        switch action {
        case .startup:
            Log.deleteLogs()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}
