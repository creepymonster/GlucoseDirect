//
//  ReadGlucose.swift
//  GlucoseDirect
//

import AVFoundation
import Combine
import Foundation

func readAloudMiddelware() -> Middleware<AppState, AppAction> {
    return readAloudMiddelware(service: LazyService<ReadAloudService>(initialization: {
        ReadAloudService()
    }))
}

private func readAloudMiddelware(service: LazyService<ReadAloudService>) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .addGlucose(glucose: let glucose):
            guard state.readGlucose else {
                break
            }

            guard glucose.type == .cgm else {
                break
            }

            service.value.readGlucose(sensorInterval: state.sensorInterval, glucose: glucose, glucoseUnit: state.glucoseUnit, alarmLow: state.alarmLow, alarmHigh: state.alarmHigh)

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - ReadAloudService

private class ReadAloudService {
    // MARK: Lifecycle

    init() {
        DirectLog.info("Create ReadAloudService")
    }

    // MARK: Internal

    func readGlucose(sensorInterval: Int, glucose: Glucose, glucoseUnit: GlucoseUnit, alarmLow: Int, alarmHigh: Int) {
        guard let glucoseValue = glucose.glucoseValue else {
            DirectLog.info("Guard: glucose.glucoseValue is nil")
            return
        }

        var alarm: AlarmType = .none
        if glucoseValue < alarmLow {
            alarm = .low
        } else if glucoseValue > alarmHigh {
            alarm = .high
        }

        if glucose.is5Minutely && alarm != .none || alarm != self.alarm || sensorInterval > 1 {
            read(glucoseValue: glucoseValue, glucoseUnit: glucoseUnit, glucoseTrend: glucose.trend, alarm: alarm)

            self.glucose = glucose
            self.alarm = alarm
        } else if glucose.is10Minutely || self.glucose == nil || self.glucose?.trend != glucose.trend || self.glucose?.type != glucose.type {
            read(glucoseValue: glucoseValue, glucoseUnit: glucoseUnit, glucoseTrend: glucose.trend)

            self.glucose = glucose
            self.alarm = alarm
        }
    }

    // MARK: Private

    private lazy var speechSynthesizer: AVSpeechSynthesizer = .init()

    private var glucose: Glucose?
    private var alarm: AlarmType = .none

    private lazy var voice: AVSpeechSynthesisVoice? = {
        for availableVoice in AVSpeechSynthesisVoice.speechVoices() {
            if availableVoice.language == AVSpeechSynthesisVoice.currentLanguageCode(), availableVoice.quality == AVSpeechSynthesisVoiceQuality.enhanced {
                DirectLog.info("Found enhanced voice: \(availableVoice.name)")

                return availableVoice
            }
        }

        DirectLog.info("Use default voice for language")

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
        DirectLog.info("read: \(glucoseValue.asGlucose(unit: glucoseUnit)) \(glucoseUnit.readable) \(glucoseTrend?.readable)")

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

// TEST
