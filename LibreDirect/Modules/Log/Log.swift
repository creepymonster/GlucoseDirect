//
//  ActionAppLog.swift
//  LibreDirect
//

import Combine
import Foundation
import OSLog
import SwiftUI

func logMiddleware() -> Middleware<AppState, AppAction> {
    return logMiddleware(service: SendLogsService())
}

private func logMiddleware(service: SendLogsService) -> Middleware<AppState, AppAction> {
    return { _, action, _ in
        AppLog.info("Triggered action: \(action)")

        switch action {
        case .startup:
            service.deleteLogs()

        case .deleteLogs:
            service.deleteLogs()

        case .sendLogs:
            service.sendLog(fileUrl: AppLog.getLogsUrl())

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendLogsService

private class SendLogsService {
    func deleteLogs() {
        AppLog.deleteLogs()
    }

    func sendLog(fileUrl: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)

        let foregroundWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }.first

        foregroundWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
}
