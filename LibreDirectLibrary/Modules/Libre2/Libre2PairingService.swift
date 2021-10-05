//
//  SensorPairing.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine
import CoreNFC

typealias Libre2PairingHandler = (_ uuid: Data, _ patchInfo: Data, _ fram: Data, _ streamingEnabled: Bool) -> Void

class Libre2PairingService: NSObject, NFCTagReaderSessionDelegate {
    private var session: NFCTagReaderSession?
    private var completionHandler: Libre2PairingHandler?

    private let nfcQueue = DispatchQueue(label: "libre-direct.nfc-queue")
    private let accessQueue = DispatchQueue(label: "libre-direct.nfc-access-queue")

    private let unlockCode: UInt32 = 42

    func pairSensor(completionHandler: @escaping Libre2PairingHandler) {
        self.completionHandler = completionHandler

        if NFCTagReaderSession.readingAvailable {
            accessQueue.async {
                self.session = NFCTagReaderSession(pollingOption: .iso15693, delegate: self, queue: self.nfcQueue)
                self.session?.alertMessage = LocalizedString("Hold the top of your iPhone near the sensor to pair", comment: "")
                self.session?.begin()
            }
        }
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let firstTag = tags.first else {
            return
        }
        
        guard case .iso15693(let tag) = firstTag else {
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
                case .failure(_):
                    return
                    
                case .success(_):
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
                                        if data.count > 0 {
                                            fram.append(data)
                                        }
                                    }

                                    // get sensorUID and patchInfo and send to delegate
                                    let sensorUID = Data(tag.identifier.reversed())
                                    let patchInfo = response

                                    // patchInfo should have length 6, which sometimes is not the case, as there are occuring crashes in nfcCommand and Libre2BLEUtilities.streamingUnlockPayload
                                    guard patchInfo.count >= 6 else {
                                        return
                                    }

                                    let subCmd: Subcommand = .enableStreaming
                                    let cmd = self.nfcCommand(subCmd, unlockCode: self.unlockCode, patchInfo: patchInfo, sensorUID: sensorUID)

                                    tag.customCommand(requestFlags: .highDataRate, customCommandCode: Int(cmd.code), customRequestParameters: cmd.parameters) { response, error in
                                        var streamingEnabled = false

                                        if subCmd == .enableStreaming && response.count == 6 {
                                            streamingEnabled = true
                                        }

                                        session.invalidate()

                                        let decryptedFram = PreLibre2.decryptFRAM(sensorUID: sensorUID, patchInfo: patchInfo, fram: fram)
                                        if let decryptedFram = decryptedFram {
                                            self.completionHandler?(sensorUID, patchInfo, decryptedFram, streamingEnabled)
                                            
                                        } else {
                                            self.completionHandler?(sensorUID, patchInfo, fram, streamingEnabled)
                                            
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
            y = UInt16(patchInfo[4...5]) ^ UInt16(b[1], b[0])
        } else {
            y = 0x1b6a
        }

        if b.count > 0 {
            parameters += b
        }

        if code.rawValue < 0x20 {
            let d = PreLibre2.usefulFunction(sensorUID: sensorUID, x: UInt16(code.rawValue), y: y)
            parameters += d
        }

        return NFCCommand(code: 0xA1, parameters: parameters)
    }
}

// MARK: - fileprivate
fileprivate struct NFCCommand {
    let code: UInt8
    let parameters: Data
}

fileprivate enum Subcommand: UInt8, CustomStringConvertible {
    case activate = 0x1b
    case enableStreaming = 0x1e

    var description: String {
        switch self {
        case .activate: return "activate"
        case .enableStreaming: return "enable BLE streaming"
        }
    }
}

