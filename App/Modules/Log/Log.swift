//
//  ActionAppLog.swift
//  GlucoseDirect
//

import Combine
import Foundation
import OSLog
import SwiftUI

func logMiddleware() -> Middleware<DirectState, DirectAction> {
    return logMiddleware(service: SendLogsService())
}

private func logMiddleware(service: SendLogsService) -> Middleware<DirectState, DirectAction> {
    return { _, action, _ in
        switch action {
        case .setBloodGlucoseValues(glucoseValues: _):
            break
            
        case .setSensorGlucoseValues(glucoseValues: _):
            break
            
        case .setBloodGlucoseHistory(glucoseHistory: _):
            break
            
        case .setSensorGlucoseHistory(glucoseHistory: _):
            break
            
        case .setSensorErrorValues(errorValues: _):
            break
            
        case .setNightscoutURL(url: _):
            break
            
        case .setNightscoutSecret(apiSecret: _):
            break
            
        case .startup:
            service.deleteLogs()

        case .deleteLogs:
            service.deleteLogs()
            
        case .sendDatabase:
            let filename = "GlucoseDirect.sqlite"
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = documentDirectory.appendingPathComponent(filename)
            
            service.sendFile(fileURL: path)

        case .sendLogs:
            service.sendFile(fileURL: DirectLog.getLogsURL())

        default:
            DirectLog.info("Triggered action: \(action)")

            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendLogsService

private class SendLogsService {
    func deleteLogs() {
        DirectLog.deleteLogs()
    }

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
