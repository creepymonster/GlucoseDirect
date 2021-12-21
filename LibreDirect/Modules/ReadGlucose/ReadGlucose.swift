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

        var glucoseString: String

        if let speakableTrend = glucoseTrend?.speakable {
            glucoseString = String(format: LocalizedString("Speakable glucose with trend: %1$@ %2$@, %3$@"), glucoseValue.asGlucose(unit: glucoseUnit), glucoseUnit.speakable, speakableTrend)
        } else {
            glucoseString = String(format: LocalizedString("Speakable glucose: %1$@ %2$@"), glucoseValue.asGlucose(unit: glucoseUnit), glucoseUnit.speakable)
        }

        let glucoseUtterance = AVSpeechUtterance(string: glucoseString)
        speechSynthesizer.speak(glucoseUtterance)
    }
}

extension GlucoseUnit {
    var speakable: String {
        switch self {
        case .mgdL:
            return LocalizedString("Speakable miligram")
        case .mmolL:
            return LocalizedString("Speakable milimol")
        }
    }
}

extension SensorTrend {
    var speakable: String? {
        switch self {
        case .falling:
            return LocalizedString("Speakable falling")
        case .fastFalling:
            return LocalizedString("Speakable fast falling")
        case .rapidlyFalling:
            return LocalizedString("Speakable rapidly falling")
        case .rising:
            return LocalizedString("Speakable rising")
        case .fastRising:
            return LocalizedString("Speakable fast rising")
        case .rapidlyRising:
            return LocalizedString("Speakable rapidly rising")
        default:
            return nil
        }
    }
}
