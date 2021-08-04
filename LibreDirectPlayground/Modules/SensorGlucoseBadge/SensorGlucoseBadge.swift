//
//  SensorGlucoseBadge.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 24.07.21.
//

import Foundation
import Combine
import UserNotifications
import UIKit

func sensorGlucoseBadgeMiddelware(service: SensorGlucoseBadgeService) -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .setSensorReading(readingUpdate: let readingUpdate):
            if state.glucoseUnit == .mgdL {
                service.setGlucoseBadge(glucose: readingUpdate.glucose.glucoseFiltered)
            } else {
                service.setGlucoseBadge(glucose: 0)
            }

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}

class SensorGlucoseBadgeService: NotificationCenterService {
    func setGlucoseBadge(glucose: Int) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        ensureCanSendNotification { ensured in
            Log.info("Glucose badge, ensured: \(ensured)")

            guard ensured else {
                return
            }

            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = glucose
            }
        }
    }
}
