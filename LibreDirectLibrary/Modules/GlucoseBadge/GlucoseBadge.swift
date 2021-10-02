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

public func glucoseBadgeMiddelware() -> Middleware<AppState, AppAction> {
    return glucoseBadgeMiddelware(service: glucoseBadgeService())
}

func glucoseBadgeMiddelware(service: glucoseBadgeService) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .setSensorReading(glucose: let glucose):
            if store.state.glucoseUnit == .mgdL {
                service.setGlucoseBadge(glucose: glucose.glucoseFiltered)
            } else {
                service.setGlucoseBadge(glucose: 0)
            }

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}

class glucoseBadgeService {
    func setGlucoseBadge(glucose: Int) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
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
