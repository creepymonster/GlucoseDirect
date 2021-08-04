//
//  SensorGlucoseSpeak.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 03.08.21.
//

import Foundation
import Combine
import UserNotifications

func sensorGlucoseSpeakMiddelware(service: SensorGlucoseSpeakService) -> Middleware<AppState, AppAction> {
    return { state, action in
        switch action {
        case .setSensorReading(readingUpdate: let readingUpdate):
            service.speakGlucose(glucose: readingUpdate.glucose.glucoseFiltered.asGlucose(unit: state.glucoseUnit))

        default:
            break

        }

        return Empty().eraseToAnyPublisher()
    }
}

class SensorGlucoseSpeakService {
    func speakGlucose(glucose: String) {

    }
}
