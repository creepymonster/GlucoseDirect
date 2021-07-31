//
//  WidgetUpdate.swift
//  LibreDirectPlayground
//
//  Created by creepymonster on 28.07.21.
//

import Foundation
import Combine
import WidgetKit

func widgetUpdaterMiddleware() -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .setSensorReading:
            let date = Date().rounded(on: 1, .minute)
            let minutes = Calendar.current.component(.minute, from: date)

            guard minutes % 5 == 0 else {
                Log.info("Stop the widget update, trigger only every 5 minutes.")
                
                break
            }
            
            Log.info("Trigger the widget update")
            WidgetCenter.shared.reloadTimelines(ofKind: Constants.WidgetKind)

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}
