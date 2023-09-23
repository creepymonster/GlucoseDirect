//
//  ActionAppLog.swift
//  GlucoseDirect
//

import Combine
import Foundation
import OSLog
import SwiftUI

func logMiddleware() -> Middleware<DirectState, DirectAction> {
    return logMiddleware(sendService: SendService(), importService: ImportService())
}

private func logMiddleware(sendService: SendService, importService: ImportService) -> Middleware<DirectState, DirectAction> {
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
            return Just(DirectAction.sendFile(fileURL: DataStore.shared.databaseURL))
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()

        case .sendLogs:
            return Just(DirectAction.sendFile(fileURL: DirectLog.logsURL))
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()
            
        case .sendFile(fileURL: let fileURL):
            sendService.sendFile(fileURL: fileURL)

        case .importDatabase(url: let fileURL):
            return Just(DirectAction.importFile(srcUrl: fileURL, dstUrl: DataStore.shared.databaseURL))
                .setFailureType(to: DirectError.self)
                .eraseToAnyPublisher()
        
        case .importFile(srcUrl: let srcUrl, dstUrl: let dstUrl):
            importService.importFile(srcUrl: srcUrl, dstUrl: dstUrl)

        default:
            DirectLog.info("Triggered action: \(action)")
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendService

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

// MARK: - ImportService

private class ImportService {
    func importFile(srcUrl: URL, dstUrl: URL) {
        do {
            let isSrcSecurityScoped = srcUrl.startAccessingSecurityScopedResource()
            let isDstSecurityScoped = dstUrl.startAccessingSecurityScopedResource()

            if FileManager.default.fileExists(atPath: dstUrl.path) {
                try FileManager.default.removeItem(at: dstUrl)
            }
            try FileManager.default.copyItem(at: srcUrl, to: dstUrl)

            if isSrcSecurityScoped {
                srcUrl.stopAccessingSecurityScopedResource()
            }
            if isDstSecurityScoped {
                dstUrl.stopAccessingSecurityScopedResource()
            }
        } catch let writeError {
            DirectLog.error("Error creating a file \(dstUrl) : \(writeError)")
        }
    }
}
