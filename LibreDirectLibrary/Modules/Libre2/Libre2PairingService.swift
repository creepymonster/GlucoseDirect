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
        guard let firstTag = tags.first else { return }
        guard case .iso15693(let tag) = firstTag else { return }

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
                            tag.readMultipleBlocks(
                                requestFlags: [.highDataRate, .address],
                                blockRange: NSRange(UInt8(i * requestBlocks) ... UInt8(i * requestBlocks + (i == requests - 1 ? (remainder == 0 ? requestBlocks : remainder) : requestBlocks) - (requestBlocks > 1 ? 1 : 0)))
                            ) { blockArray, error in
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

                                    self.readRaw(0xF860, 43 * 8, tag: tag) { _, _, _ in
                                        self.readRaw(0x1A00, 64, tag: tag) { _, _, _ in
                                            self.readRaw(0xFFAC, 36, tag: tag) { _, _, _ in
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

                                                    //self.delegate?.streamingEnabled(successful: streamingEnabled)
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
        }
    }

    private func readRaw(_ address: UInt16, _ bytes: Int, buffer: Data = Data(), tag: NFCISO15693Tag, handler: @escaping (UInt16, Data, Error?) -> Void) {
        var buffer = buffer
        let addressToRead = address + UInt16(buffer.count)

        var remainingBytes = bytes
        let bytesToRead = remainingBytes > 24 ? 24 : bytes

        var remainingWords = bytes / 2
        if bytes % 2 == 1 || (bytes % 2 == 0 && addressToRead % 2 == 1) { remainingWords += 1 }
        let wordsToRead = UInt8(remainingWords > 12 ? 12 : remainingWords) // real limit is 15

        // this is for libre 2 only, ignoring other libre types
        let readRawCommand = NFCCommand(code: 0xB3, parameters: Data([UInt8(addressToRead & 0x00FF), UInt8(addressToRead >> 8), wordsToRead]))

        tag.customCommand(requestFlags: .highDataRate, customCommandCode: Int(readRawCommand.code), customRequestParameters: readRawCommand.parameters) { response, error in
            var data = response

            if error != nil {
                remainingBytes = 0
            } else {
                if addressToRead % 2 == 1 { data = data.subdata(in: 1 ..< data.count) }
                if data.count - Int(bytesToRead) == 1 { data = data.subdata(in: 0 ..< data.count - 1) }
            }

            buffer += data
            remainingBytes -= data.count

            if remainingBytes == 0 {
                handler(address, buffer, error)
            } else {
                self.readRaw(address, remainingBytes, buffer: buffer, tag: tag) { address, data, error in handler(address, data, error) }
            }
        }
    }

    private func writeRaw(_ address: UInt16, _ data: Data, tag: NFCISO15693Tag, handler: @escaping (UInt16, Data, Error?) -> Void) {
        let backdoor = "deadbeef".utf8

        tag.customCommand(requestFlags: .highDataRate, customCommandCode: 0xA4, customRequestParameters: Data(backdoor)) {
            response, error in

            let addressToRead = (address / 8) * 8
            let startOffset = Int(address % 8)
            let endAddressToRead = ((Int(address) + data.count - 1) / 8) * 8 + 7
            let blocksToRead = (endAddressToRead - Int(addressToRead)) / 8 + 1

            self.readRaw(addressToRead, blocksToRead * 8, tag: tag) { readAddress, readData, error in
                if error != nil {
                    handler(address, data, error)
                    return
                }

                var bytesToWrite = readData
                bytesToWrite.replaceSubrange(startOffset ..< startOffset + data.count, with: data)

                let startBlock = Int(addressToRead / 8)
                let blocks = bytesToWrite.count / 8

                if address < 0xF860 { // lower than FRAM blocks
                    for i in 0 ..< blocks {
                        let blockToWrite = bytesToWrite[i * 8 ... i * 8 + 7]

                        // FIXME: doesn't work as the custom commands C1 or A5 for other chips
                        tag.extendedWriteSingleBlock(requestFlags: .highDataRate, blockNumber: startBlock + i, dataBlock: blockToWrite) { error in
                            if error != nil {
                                if i != blocks - 1 { return }
                            }

                            if i == blocks - 1 {
                                tag.customCommand(requestFlags: .highDataRate, customCommandCode: 0xA2, customRequestParameters: Data(backdoor)) { response, error in
                                    handler(address, data, error)
                                }
                            }
                        }
                    }

                } else { // address >= 0xF860: write to FRAM blocks
                    let requestBlocks = 2 // 3 doesn't work
                    let requests = Int(ceil(Double(blocks) / Double(requestBlocks)))
                    let remainder = blocks % requestBlocks
                    var blocksToWrite = [Data](repeating: Data(), count: blocks)

                    for i in 0 ..< blocks {
                        blocksToWrite[i] = Data(bytesToWrite[i * 8 ... i * 8 + 7])
                    }

                    for i in 0 ..< requests {
                        let startIndex = startBlock - 0xF860 / 8 + i * requestBlocks
                        let endIndex = startIndex + (i == requests - 1 ? (remainder == 0 ? requestBlocks : remainder) : requestBlocks) - (requestBlocks > 1 ? 1 : 0)
                        let blockRange = NSRange(UInt8(startIndex) ... UInt8(endIndex))

                        var dataBlocks = [Data]()
                        for j in startIndex ... endIndex { dataBlocks.append(blocksToWrite[j - startIndex]) }

                        // TODO: write to 16-bit addresses as the custom cummand C4 for other chips
                        tag.writeMultipleBlocks(requestFlags: [.highDataRate, .address], blockRange: blockRange, dataBlocks: dataBlocks) { error in // TEST
                            if error != nil {
                                if i != requests - 1 { return }
                            }

                            if i == requests - 1 {
                                // Lock
                                tag.customCommand(requestFlags: .highDataRate, customCommandCode: 0xA2, customRequestParameters: Data(backdoor)) {
                                    response, error in

                                    handler(address, data, error)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func nfcCommand(_ code: Subcommand, unlockCode: UInt32, patchInfo: Data, sensorUID: Data) -> NFCCommand {
        var b: [UInt8] = []
        var y: UInt16

        if code == .enableStreaming {
            // Enables Bluetooth on Libre 2. Returns peripheral MAC address to connect to.
            // unlockCode could be any 32 bit value. The unlockCode and sensor Uid / patchInfo
            // will have also to be provided to the login function when connecting to peripheral.
            b = [UInt8(unlockCode & 0xFF), UInt8((unlockCode >> 8) & 0xFF), UInt8((unlockCode >> 16) & 0xFF), UInt8((unlockCode >> 24) & 0xFF)]
            y = UInt16(patchInfo[4...5]) ^ UInt16(b[1], b[0])
        } else {
            y = 0x1b6a
        }

        let d = PreLibre2.usefulFunction(sensorUID: sensorUID, x: UInt16(code.rawValue), y: y)

        var parameters = Data([code.rawValue])

        if code == .enableStreaming {
            parameters += b
        }

        parameters += d

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
    case unknown0x1a = 0x1a
    case unknown0x1c = 0x1c
    case unknown0x1d = 0x1d
    case unknown0x1f = 0x1f

    var description: String {
        switch self {
        case .activate: return "activate"
        case .enableStreaming: return "enable BLE streaming"
        default: return "[unknown: 0x\(String(format: "%x", rawValue))]"
        }
    }
}

