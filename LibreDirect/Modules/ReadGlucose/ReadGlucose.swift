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
            guard state.readGlucose else {
                break
            }

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
        AppLog.info("read: \(glucoseValue) \(glucoseUnit.readable) \(glucoseTrend?.readable)")

        var glucoseString: String

        if let readableTrend = glucoseTrend?.readable {
            glucoseString = String(format: LocalizedString("Readable glucose with trend: %1$@ %2$@, %3$@"), glucoseValue.asGlucose(unit: glucoseUnit), glucoseUnit.readable, readableTrend)
        } else {
            glucoseString = String(format: LocalizedString("Readable glucose: %1$@ %2$@"), glucoseValue.asGlucose(unit: glucoseUnit), glucoseUnit.readable)
        }

        let glucoseUtterance = AVSpeechUtterance(string: glucoseString)
        glucoseUtterance.voice = AVSpeechSynthesisVoice(language: NSLocale.current.languageCode)
        
        speechSynthesizer.speak(glucoseUtterance)
    }
}

extension GlucoseUnit {
    var readable: String {
        switch self {
        case .mgdL:
            return LocalizedString("Readable miligram")
        case .mmolL:
            return LocalizedString("Readable milimol")
        }
    }
}

extension SensorTrend {
    var readable: String? {
        switch self {
        case .falling:
            return LocalizedString("Readable falling")
        case .fastFalling:
            return LocalizedString("Readable fast falling")
        case .rapidlyFalling:
            return LocalizedString("Readable rapidly falling")
        case .rising:
            return LocalizedString("Readable rising")
        case .fastRising:
            return LocalizedString("Readable fast rising")
        case .rapidlyRising:
            return LocalizedString("Readable rapidly rising")
        default:
            return nil
        }
    }
}
