//
//  Libre2.swift
//  LibreDirect
//

import Combine
import Foundation

@available(iOS 15.0, *)
func libre2Middelware() -> Middleware<AppState, AppAction> {
    return sensorMiddelware(service: Libre2Service())
}
