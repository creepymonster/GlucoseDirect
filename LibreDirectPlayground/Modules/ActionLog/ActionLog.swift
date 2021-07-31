//
//  Log.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 19.07.21.
//

import Foundation
import Combine

func actionLogMiddleware() -> Middleware<AppState, AppAction> {
    return { state, action in
        Log.info("Triggered action: \(action)")

        return Empty().eraseToAnyPublisher()
    }
}
