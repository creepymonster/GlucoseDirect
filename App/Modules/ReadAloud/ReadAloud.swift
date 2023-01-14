//
//  ReadGlucose.swift
//  GlucoseDirect
//

import AVFoundation
import Combine
import Foundation

func readAloudMiddelware() -> Middleware<DirectState, DirectAction> {
    return readAloudMiddelware(service: LazyService<ReadAloudService>(initialization: {
        ReadAloudService()
    }))
}

private func readAloudMiddelware(service: LazyService<ReadAloudService>) -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .addSensorGlucose(glucoseValues: let glucoseValues):
            guard state.readGlucose else {
                break
            }

            guard let glucose = glucoseValues.last else {
                break
            }

            let alarm = state.isAlarm(glucoseValue: glucose.glucoseValue)
            service.value.readGlucose(sensorInterval: state.sensorInterval, glucose: glucose, glucoseUnit: state.glucoseUnit, alarm: alarm)

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

    func readGlucose(sensorInterval: Int, glucose: SensorGlucose, glucoseUnit: GlucoseUnit, alarm: Alarm) {
        if alarm != self.alarm || sensorInterval > 1 {
            read(glucoseValue: glucose.glucoseValue, glucoseUnit: glucoseUnit, glucoseTrend: glucose.trend, alarm: alarm)

            self.glucose = glucose
            self.alarm = alarm
        } else if glucose.isMinutly(ofMinutes: 10) || self.glucose == nil || self.glucose?.trend != glucose.trend {
            read(glucoseValue: glucose.glucoseValue, glucoseUnit: glucoseUnit, glucoseTrend: glucose.trend)

            self.glucose = glucose
            self.alarm = alarm
        }
    }

    // MARK: Private

    private lazy var speechSynthesizer: AVSpeechSynthesizer = .init()

    private var glucose: SensorGlucose?
    private var alarm: Alarm = .none

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

    private func read(glucoseValue: Int, glucoseUnit: GlucoseUnit, glucoseTrend: SensorTrend? = nil, alarm: Alarm = .none) {
        DirectLog.info("read: \(glucoseValue.asGlucose(glucoseUnit: glucoseUnit)) \(glucoseUnit.readable) \(glucoseTrend?.readable)")

        var glucoseString: String

        if alarm == .lowAlarm {
            glucoseString = String(format: LocalizedString("Readable low glucose: %1$@ %2$@"), glucoseValue.asGlucose(glucoseUnit: glucoseUnit), glucoseUnit.readable)
        } else if alarm == .highAlarm, alarm != self.alarm {
            glucoseString = String(format: LocalizedString("Readable high glucose: %1$@ %2$@"), glucoseValue.asGlucose(glucoseUnit: glucoseUnit), glucoseUnit.readable)
        } else if let readableTrend = glucoseTrend?.readable {
            glucoseString = String(format: LocalizedString("Readable glucose with trend: %1$@ %2$@, %3$@"), glucoseValue.asGlucose(glucoseUnit: glucoseUnit), glucoseUnit.readable, readableTrend)
        } else {
            glucoseString = String(format: LocalizedString("Readable glucose: %1$@ %2$@"), glucoseValue.asGlucose(glucoseUnit: glucoseUnit), glucoseUnit.readable)
        }

        let glucoseUtterance = AVSpeechUtterance(string: glucoseString)
        if let voice = voice {
            glucoseUtterance.voice = voice
        }

        speechSynthesizer.speak(glucoseUtterance)
    }
}

// MARK: - AlarmType

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
