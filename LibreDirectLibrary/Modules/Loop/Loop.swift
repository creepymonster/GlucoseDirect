//
//  Loop.swift
//  LibreDirect
//

import Combine
import Foundation

typealias LoopUpdateHandler = (_ value: Glucose) -> Void

func loopMiddleware(updateHandler: @escaping LoopUpdateHandler) -> Middleware<AppState, AppAction> {
    return { _, action, _ in
        switch action {
        case .addGlucose(glucose: let glucose):
            guard glucose.is5Minutely else {
                break
            }

            updateHandler(glucose)

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}
