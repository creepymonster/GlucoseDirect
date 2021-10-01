//
//  Loop.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 01.09.21. 
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation
import Combine

public typealias LoopUpdateHandler = (_ value: SensorGlucose) -> Void

public func loopMiddleware(updateHandler: @escaping LoopUpdateHandler) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .setSensorReading(glucose: let glucose):
            updateHandler(glucose)

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}
