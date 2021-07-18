//
//  Logging.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

func printLogMiddleware() -> Middleware<AppState, AppAction> {
    return { state, action in
        print("Triggered \(action)")

        return Empty().eraseToAnyPublisher()
    }
}
