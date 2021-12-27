//
//  ReadGlucose.swift
//  LibreDirect
//

import AVFoundation
import Combine
import Foundation

func readAloudMiddelware() -> Middleware<AppState, AppAction> {
    return readGlucoseMiddelware(service: {
        ReadAloudService()
    }())
}

private func readGlucoseMiddelware(service: ReadAloudService) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .addGlucoseValues(glucoseValues: let glucoseValues):
            guard state.readGlucose else {
                break
            }

            service.readGlucoseValues(glucoseValues: glucoseValues, glucoseUnit: state.glucoseUnit, alarmLow: state.alarmLow, alarmHigh: state.alarmHigh)

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - ReadAloudService

private class ReadAloudService {
    // MARK: Internal

    func readGlucoseValues(glucoseValues: [Glucose], glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int) {
        AppLog.info("readGlucoseValues: \(glucoseValues.count) \(glucoseUnit.localizedString)")

        guard let glucose = glucoseValues.last else {
            AppLog.info("Guard: glucoseValues.last is nil")
            return
        }

        guard glucose.type != .bgm else {
            AppLog.info("Guard: glucose.type is .bgm")
            return
        }

        guard let glucoseValue = glucose.glucoseValue else {
            AppLog.info("Guard: glucose.glucoseValue is nil")
            return
        }

        var alarm: AlarmType = .none
        if glucoseValue < alarmLow {
            alarm = .low
        } else if glucoseValue > alarmHigh {
            alarm = .high
        }

        if alarm != self.alarm || (glucose.is5Minutely && alarm != .none) {
            read(glucoseValue: glucoseValue, glucoseUnit: glucoseUnit, glucoseTrend: glucose.trend, alarm: alarm)

            self.glucose = glucose
            self.alarm = alarm
        } else if glucoseValues.count > 1 || glucose.is10Minutely || self.glucose == nil || self.glucose!.trend != glucose.trend || self.glucose!.type != glucose.type {
            if glucose.type == .cgm {
                read(glucoseValue: glucoseValue, glucoseUnit: glucoseUnit, glucoseTrend: glucose.trend)
            } else if glucose.type == .none {
                read(text: LocalizedString("Attention, faulty value received"))
            }

            self.glucose = glucose
            self.alarm = alarm
        }
    }

    // MARK: Private

    private var speechSynthesizer: AVSpeechSynthesizer = {
        AVSpeechSynthesizer()
    }()

    private var glucose: Glucose?
    private var alarm: AlarmType = .none

    private var voice: AVSpeechSynthesisVoice? = {
        for availableVoice in AVSpeechSynthesisVoice.speechVoices() {
            if availableVoice.language == AVSpeechSynthesisVoice.currentLanguageCode(), availableVoice.quality == AVSpeechSynthesisVoiceQuality.enhanced {
                AppLog.info("Found enhanced voice: \(availableVoice.name)")
                return availableVoice
            }
        }

        AppLog.info("Use default voice for language")
        return AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
    }()

    private func read(text: String) {
        let textUtterance = AVSpeechUtterance(string: text)
        if let voice = voice {
            textUtterance.voice = voice
        }

        speechSynthesizer.speak(textUtterance)
    }

    private func read(glucoseValue: Int, glucoseUnit: GlucoseUnit, glucoseTrend: SensorTrend? = nil, alarm: AlarmType = .none) {
        AppLog.info("read: \(glucoseValue.asGlucose(unit: glucoseUnit)) \(glucoseUnit.readable) \(glucoseTrend?.readable)")

        var glucoseString: String

        if alarm == .low {
            glucoseString = String(format: LocalizedString("Readable low glucose: %1$@ %2$@"), glucoseValue.asGlucose(unit: glucoseUnit), glucoseUnit.readable)
        } else if alarm == .high, alarm != self.alarm {
            glucoseString = String(format: LocalizedString("Readable high glucose: %1$@ %2$@"), glucoseValue.asGlucose(unit: glucoseUnit), glucoseUnit.readable)
        } else if let readableTrend = glucoseTrend?.readable {
            glucoseString = String(format: LocalizedString("Readable glucose with trend: %1$@ %2$@, %3$@"), glucoseValue.asGlucose(unit: glucoseUnit), glucoseUnit.readable, readableTrend)
        } else {
            glucoseString = String(format: LocalizedString("Readable glucose: %1$@ %2$@"), glucoseValue.asGlucose(unit: glucoseUnit), glucoseUnit.readable)
        }

        let glucoseUtterance = AVSpeechUtterance(string: glucoseString)
        if let voice = voice {
            glucoseUtterance.voice = voice
        }

        speechSynthesizer.speak(glucoseUtterance)
    }
}

// MARK: - AlarmType

enum AlarmType {
    case none
    case low
    case high
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
