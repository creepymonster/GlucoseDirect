//
//  Widget.swift
//  GlucoseDirectApp
//

import Combine
import Foundation
import WidgetKit

func widgetCenterMiddleware() -> Middleware<DirectState, DirectAction> {
    return { _, action, _ in
        DirectLog.info("Triggered action: \(action)")

        switch action {
        case .startup:
            WidgetCenter.shared.reloadAllTimelines()

        case .setGlucoseUnit(unit: _):
            WidgetCenter.shared.reloadAllTimelines()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}
