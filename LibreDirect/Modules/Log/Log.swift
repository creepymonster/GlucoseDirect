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
    return { store, action, _ in
        AppLog.info("Triggered action: \(action)")

        switch action {
        case .collectLogs:
            AppLog.getLogEntries(hours: 24) { entries in
                store.dispatch(.collectLogsCompleted(entries: entries))
            }
            
        case .collectLogsCompleted(entries: let entries):
            service.sendLogfile(entries: entries)

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendLogsService

private class SendLogsService {
    // MARK: Internal

    func sendLogfile(entries: [OSLogEntryLog]) {
        let logContent = entries.map { entry in
            "[\(entry.level.rawValue)] \(entry.date): \(entry.composedMessage)"
        }.joined(separator: "\n")

        let fileUrl = getDocumentDirectory().appendingPathComponent(SendLogsService.filename)
        
        deleteLogfile(fileUrl: fileUrl)
        saveLogfile(fileUrl: fileUrl, content: logContent)
        
        let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
        
        let foregroundWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
        
        foregroundWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }

    // MARK: Private

    private static let filename = "GlucoseDirect.log"

    private func deleteLogfile(fileUrl: URL) {
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                try FileManager.default.removeItem(at: fileUrl)
            } catch {
                AppLog.error("Failed to remove file: \(error.localizedDescription)")
            }
        }
    }

    private func saveLogfile(fileUrl: URL, content: String) {
        do {
            try content.write(to: fileUrl, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            AppLog.error("Failed to write file: \(error.localizedDescription)")
        }
    }

    private func getDocumentDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
