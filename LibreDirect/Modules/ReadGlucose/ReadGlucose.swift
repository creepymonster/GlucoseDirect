//
//  ReadGlucose.swift
//  LibreDirect
//

import AVFoundation
import Combine
import Foundation

func readGlucoseMiddelware() -> Middleware<AppState, AppAction> {
    return readGlucoseMiddelware(service: ReadGlucoseService())
}

private func readGlucoseMiddelware(service: ReadGlucoseService) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .addGlucoseValues(glucoseValues: let glucoseValues):
            service.readGlucoseValues(glucoseValues: glucoseValues, glucoseUnit: state.glucoseUnit)

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - ReadGlucoseService

private class ReadGlucoseService {
    // MARK: Internal

    func readGlucoseValues(glucoseValues: [Glucose], glucoseUnit: GlucoseUnit) {
        AppLog.info("readGlucoseValues: \(glucoseValues.count) \(glucoseUnit.localizedString)")

        guard let glucose = glucoseValues.last, glucose.type == .cgm else {
            return
        }

        if let glucoseValue = glucose.glucoseValue, glucoseValues.count > 1 || glucose.is5Minutely || lastGlucose == nil || lastGlucose!.trend != glucose.trend {
            read(glucoseValue: glucoseValue, glucoseUnit: glucoseUnit, glucoseTrend: glucose.trend)
            lastGlucose = glucose
        }
    }

    // MARK: Private

    private var speechSynthesizer = AVSpeechSynthesizer()
    private var lastGlucose: Glucose?

    private func read(glucoseValue: Int, glucoseUnit: GlucoseUnit, glucoseTrend: SensorTrend? = nil) {
        AppLog.info("read: \(glucoseValue) \(glucoseUnit.speakable) \(glucoseTrend?.speakable)")

        var glucoseString = "Blutzucker: \(glucoseValue) \(glucoseUnit.speakable)"

        if let speakableTrend = glucoseTrend?.speakable {
            glucoseString.append(", \(speakableTrend)")
        }

        let glucoseUtterance = AVSpeechUtterance(string: glucoseString)
        speechSynthesizer.speak(glucoseUtterance)
    }
}

extension GlucoseUnit {
    var speakable: String {
        switch self {
        case .mgdL:
            return "miligram"
        case .mmolL:
            return "milimol"
        }
    }
}

extension SensorTrend {
    var speakable: String? {
        switch self {
        case .falling:
            return "fallend"
        case .fastFalling:
            return "schnell fallend"
        case .rapidlyFalling:
            return "rapide fallend"
        case .rising:
            return "steigend"
        case .fastRising:
            return "schnell steigend"
        case .rapidlyRising:
            return "rapide steigend"
        default:
            return nil
        }
    }
}
