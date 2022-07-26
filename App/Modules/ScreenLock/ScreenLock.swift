//
//  ScreenLock.swift
//  GlucoseDirect
//

import Combine
import Foundation
import UIKit

func screenLockMiddleware() -> Middleware<DirectState, DirectAction> {
    return { _, action, _ in
        switch action {
        case .setPreventScreenLock(enabled: let enabled):
            UIApplication.shared.isIdleTimerDisabled = enabled

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}
