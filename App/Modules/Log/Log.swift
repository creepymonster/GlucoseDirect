//
//  ActionAppLog.swift
//  GlucoseDirect
//

import Combine
import Foundation
import OSLog
import SwiftUI

func logMiddleware() -> Middleware<DirectState, DirectAction> {
    return logMiddleware(service: SendService())
}

private func logMiddleware(service: SendService) -> Middleware<DirectState, DirectAction> {
    return { _, action, _ in
        switch action {
        case .setBloodGlucoseValues(glucoseValues: _):
            break

        case .setSensorGlucoseValues(glucoseValues: _):
            break

        case .setSensorErrorValues(errorValues: _):
            break
            
        case .setNightscoutURL(url: _):
            break

        case .setNightscoutSecret(apiSecret: _):
            break

        case .startup:
            DirectLog.deleteLogs()

        case .deleteLogs:
            DirectLog.deleteLogs()

        case .sendDatabase:
            return Just(DirectAction.sendFile(fileURL: DataStore.shared.containerDatabaseURL))
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .sendLogs:
            return Just(DirectAction.sendFile(fileURL: DirectLog.logsURL))
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()
            
        case .sendFile(fileURL: let fileURL):
            service.sendFile(fileURL: fileURL)

        default:
            DirectLog.info("Triggered action: \(action)")
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendLogsService

private class SendService {
    func sendFile(fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        let foregroundWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }.first

        foregroundWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
}
