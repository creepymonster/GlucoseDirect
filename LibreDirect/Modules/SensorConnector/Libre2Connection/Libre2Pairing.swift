//
//  SensorPairing.swift
//  LibreDirect
//
//  Special thanks to: guidos
//

import Combine
import CoreNFC
import Foundation

// MARK: - Libre2Pairing

final class Libre2Pairing: NSObject, NFCTagReaderSessionDelegate {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<AppAction, AppError>) {
        self.subject = subject
    }

    // MARK: Internal

    func pairSensor() {
        guard subject != nil else {
            AppLog.error("Pairing, subject is nil")

            return
        }

        if NFCTagReaderSession.readingAvailable {
            session = NFCTagReaderSession(pollingOption: .iso15693, delegate: self, queue: nfcQueue)
            session?.alertMessage = LocalizedString("Hold the top edge of your iPhone close to the sensor.", comment: "")
            session?.begin()
        }
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError, readerError.code != .readerSessionInvalidationErrorUserCanceled {
            session.invalidate(errorMessage: "Connection failure: \(readerError.localizedDescription)")

            AppLog.error("Reader session didInvalidateWithError: \(readerError.localizedDescription))")
            subject?.send(.setConnectionError(errorMessage: readerError.localizedDescription, errorTimestamp: Date(), errorIsCritical: false))
            subject?.send(.setConnectionState(connectionState: .disconnected))
        } else {
            AppLog.info("Reader session didInvalidate")
            subject?.send(.setConnectionState(connectionState: .disconnected))
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let firstTag = tags.first else {
            AppLog.error("No tag")
            subject?.send(.setConnectionError(errorMessage: "No tag", errorTimestamp: Date(), errorIsCritical: false))
            subject?.send(.setConnectionState(connectionState: .disconnected))

            return
        }

        guard case .iso15693(let tag) = firstTag else {
            AppLog.error("No ISO15693 tag")
            subject?.send(.setConnectionError(errorMessage: "No ISO15693 tag", errorTimestamp: Date(), errorIsCritical: false))
            subject?.send(.setConnectionState(connectionState: .disconnected))

            return
        }

        let blocks = 43
        let requestBlocks = 3

        let requests = Int(ceil(Double(blocks) / Double(requestBlocks)))
        let remainder = blocks % requestBlocks
        var dataArray = [Data](repeating: Data(), count: blocks)

        session.connect(to: firstTag) { error in
            if error != nil {
                return
            }

            tag.getSystemInfo(requestFlags: [.address, .highDataRate]) { result in
                switch result {
                case .failure:
                    return

                case .success:
                    tag.customCommand(requestFlags: .highDataRate, customCommandCode: 0xA1, customRequestParameters: Data()) { response, error in
                        for i in 0 ..< requests {
                            let requestFlags: NFCISO15693RequestFlag = [.highDataRate, .address]
                            let blockRange = NSRange(UInt8(i * requestBlocks) ... UInt8(i * requestBlocks + (i == requests - 1 ? (remainder == 0 ? requestBlocks : remainder) : requestBlocks) - (requestBlocks > 1 ? 1 : 0)))

                            tag.readMultipleBlocks(requestFlags: requestFlags, blockRange: blockRange) { blockArray, error in
                                if error != nil {
                                    if i != requests - 1 { return }
                                } else {
                                    for j in 0 ..< blockArray.count {
                                        dataArray[i * requestBlocks + j] = blockArray[j]
                                    }
                                }

                                if i == requests - 1 {
                                    var fram = Data()

                                    for (_, data) in dataArray.enumerated() {
                                        if !data.isEmpty {
                                            fram.append(data)
                                        }
                                    }

                                    // get sensorUID and patchInfo and send to delegate
                                    let sensorUID = Data(tag.identifier.reversed())
                                    let patchInfo = response

                                    // patchInfo should have length 6, which sometimes is not the case, as there are occuring crashes in nfcCommand and Libre2BLEUtilities.streamingUnlockPayload
                                    guard patchInfo.count >= 6 else {
                                        AppLog.error("Invalid patchInfo (patchInfo not > 6)")
                                        self.subject?.send(.setConnectionError(errorMessage: "Invalid patchInfo (patchInfo not > 6)", errorTimestamp: Date(), errorIsCritical: false))
                                        self.subject?.send(.setConnectionState(connectionState: .disconnected))

                                        return
                                    }
                                    
                                    let type = SensorType(patchInfo)
                                    guard type == .libre2EU else {
                                        AppLog.error("Invalid sensor type: \(type.localizedString)")
                                        self.subject?.send(.setConnectionError(errorMessage: "Invalid sensor type: \(type.localizedString)", errorTimestamp: Date(), errorIsCritical: false))
                                        self.subject?.send(.setConnectionState(connectionState: .disconnected))

                                        return
                                    }

                                    let subCmd: Subcommand = .enableStreaming
                                    let cmd = self.nfcCommand(subCmd, unlockCode: self.unlockCode, patchInfo: patchInfo, sensorUID: sensorUID)

                                    tag.customCommand(requestFlags: .highDataRate, customCommandCode: Int(cmd.code), customRequestParameters: cmd.parameters) { response, _ in
                                        let streamingEnabled = subCmd == .enableStreaming && response.count == 6

                                        session.invalidate()

                                        guard streamingEnabled else {
                                            AppLog.error("Streaming not enabled")
                                            self.subject?.send(.setConnectionError(errorMessage: "Streaming not enabled", errorTimestamp: Date(), errorIsCritical: false))
                                            self.subject?.send(.setConnectionState(connectionState: .disconnected))

                                            return
                                        }

                                        let decryptedFram = SensorUtility.decryptFRAM(uuid: sensorUID, patchInfo: patchInfo, fram: fram)
                                        if let decryptedFram = decryptedFram {
                                            AppLog.info("Success (from decrypted fram)")
                                            self.subject?.send(.setSensor(sensor: Sensor(uuid: sensorUID, patchInfo: patchInfo, fram: decryptedFram)))
                                            self.subject?.send(.setConnectionState(connectionState: .disconnected))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Private

    private var session: NFCTagReaderSession?
    private weak var subject: PassthroughSubject<AppAction, AppError>?

    private let nfcQueue = DispatchQueue(label: "libre-direct.nfc-queue")
    private let unlockCode: UInt32 = 42

    private func nfcCommand(_ code: Subcommand, unlockCode: UInt32, patchInfo: Data, sensorUID: Data) -> NFCCommand {
        var parameters = Data([code.rawValue])

        var b: [UInt8] = []
        var y: UInt16

        if code == .enableStreaming {
            // Enables Bluetooth on Libre 2. Returns peripheral MAC address to connect to.
            // unlockCode could be any 32 bit value. The unlockCode and sensor Uid / patchInfo
            // will have also to be provided to the login function when connecting to peripheral.
            b = [
                UInt8(unlockCode & 0xFF),
                UInt8((unlockCode >> 8) & 0xFF),
                UInt8((unlockCode >> 16) & 0xFF),
                UInt8((unlockCode >> 24) & 0xFF)
            ]
            y = UInt16(patchInfo[4 ... 5]) ^ UInt16(b[1], b[0])
        } else {
            y = 0x1B6A
        }

        if !b.isEmpty {
            parameters += b
        }

        if code.rawValue < 0x20 {
            let d = SensorUtility.usefulFunction(uuid: sensorUID, x: UInt16(code.rawValue), y: y)
            parameters += d
        }

        return NFCCommand(code: 0xA1, parameters: parameters)
    }
}

// MARK: - NFCCommand

private struct NFCCommand {
    let code: UInt8
    let parameters: Data
}

// MARK: - Subcommand

private enum Subcommand: UInt8, CustomStringConvertible {
    case activate = 0x1B
    case enableStreaming = 0x1E

    // MARK: Internal

    var description: String {
        switch self {
        case .activate:
            return "activate"
        case .enableStreaming:
            return "enable BLE streaming"
        }
    }
}
