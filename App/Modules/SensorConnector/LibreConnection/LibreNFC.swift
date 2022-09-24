//
//  LibrePairing.swift
//  GlucoseDirect
//
//  Special thanks to: guidos
//

import Combine
import Foundation

#if canImport(CoreNFC)
import CoreNFC

class LibreNFC: NSObject, NFCTagReaderSessionDelegate {
    // MARK: Internal

    func readSensor(enableStreaming: Bool) async throws -> LibrePairingResult {
        self.enableStreaming = enableStreaming

        return try await withCheckedThrowingContinuation { continuation in
            activeContinuation = continuation

            if NFCTagReaderSession.readingAvailable {
                session = NFCTagReaderSession(pollingOption: .iso15693, delegate: self, queue: nfcQueue)
                session?.alertMessage = LocalizedString("Hold the top edge of your iPhone close to the sensor.")
                session?.begin()
            } else {
                returnWithError(LibrePairingError.nfcNotAvailable)
            }
        }
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let error = error as? NFCReaderError {
            if error.code != .readerSessionInvalidationErrorFirstNDEFTagRead, error.code != .readerSessionInvalidationErrorUserCanceled {
                returnWithError(LibrePairingError.unknownError)
            }
        }

        self.session = nil
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Task {
            guard let firstTag = tags.first else {
                returnWithError(LibrePairingError.noTagFound)
                return
            }

            guard case .iso15693(let tag) = firstTag else {
                returnWithError(LibrePairingError.noIsoTagFound)
                return
            }

            for retry in 0 ..< retryCount {
                do {
                    try await session.connect(to: firstTag)
                    break
                } catch {
                    if retry == retryCount - 1 {
                        returnWithError(LibrePairingError.failedToConnect)
                        return
                    } else {
                        continue
                    }
                }
            }

            let sensorUID = Data(tag.identifier.reversed())
            var patchInfo = Data()

            for retry in 0 ..< retryCount {
                do {
                    patchInfo = try await tag.customCommand(requestFlags: .highDataRate, customCommandCode: 0xA1, customRequestParameters: Data())
                    break
                } catch {
                    if retry == retryCount - 1 {
                        returnWithError(LibrePairingError.invalidPatchInfo)
                        return
                    } else {
                        continue
                    }
                }
            }

            guard patchInfo.count >= 6 else {
                returnWithError(LibrePairingError.invalidPatchInfo)
                return
            }

            let type = SensorType(patchInfo)
            
            let blocks = 43
            let requestBlocks = 3

            let requests = Int(ceil(Double(blocks) / Double(requestBlocks)))
            let remainder = blocks % requestBlocks
            var dataArray = [Data](repeating: Data(), count: blocks)

            for i in 0 ..< requests {
                let requestFlags: NFCISO15693RequestFlag = [.highDataRate, .address]
                let blockRange = NSRange(UInt8(i * requestBlocks) ... UInt8(i * requestBlocks + (i == requests - 1 ? (remainder == 0 ? requestBlocks : remainder) : requestBlocks) - (requestBlocks > 1 ? 1 : 0)))

                for retry in 0 ..< retryCount {
                    do {
                        let blockArray = try await tag.readMultipleBlocks(requestFlags: requestFlags, blockRange: blockRange)
                        for j in 0 ..< blockArray.count {
                            dataArray[i * requestBlocks + j] = blockArray[j]
                        }
                        break
                    } catch {
                        if retry == retryCount - 1 {
                            returnWithError(LibrePairingError.failedToRead)
                            return
                        } else {
                            continue
                        }
                    }
                }

                if i == requests - 1 {
                    var rxBuffer = Data()
                    for (_, data) in dataArray.enumerated() {
                        if !data.isEmpty {
                            rxBuffer.append(data)
                        }
                    }

                    guard rxBuffer.count >= 344 else {
                        returnWithError(LibrePairingError.invalidBuffer)
                        return
                    }

                    switch type {
                    case .libre1:
                        let sensor = Sensor.libreStyleSensor(uuid: sensorUID, patchInfo: patchInfo, fram: rxBuffer)
                        
                        if let factoryCalibration = sensor.factoryCalibration {
                            let readings = LibreUtility.parseFRAM(calibration: factoryCalibration, pairingTimestamp: sensor.pairingTimestamp, fram: rxBuffer)
                            
                            returnWithResult(isPaired: false, sensor: sensor, readings: readings.history + readings.trend)
                            return
                        }
                        
                    case .libreUS14day:
                        guard let fram = Libre2EUtility.decryptFRAM(uuid: sensorUID, patchInfo: patchInfo, fram: rxBuffer) else {
                            break
                        }

                        let sensor = Sensor.libreStyleSensor(uuid: sensorUID, patchInfo: patchInfo, fram: fram)
                        
                        if let factoryCalibration = sensor.factoryCalibration {
                            let readings = LibreUtility.parseFRAM(calibration: factoryCalibration, pairingTimestamp: sensor.pairingTimestamp, fram: fram)
                            
                            returnWithResult(isPaired: false, sensor: sensor, readings: readings.history + readings.trend)
                            return
                        }
                        
                    case .libre2EU:
                        guard let fram = Libre2EUtility.decryptFRAM(uuid: sensorUID, patchInfo: patchInfo, fram: rxBuffer) else {
                            break
                        }

                        let sensor = Sensor.libreStyleSensor(uuid: sensorUID, patchInfo: patchInfo, fram: fram)
                        
                        if let factoryCalibration = sensor.factoryCalibration {
                            let readings = LibreUtility.parseFRAM(calibration: factoryCalibration, pairingTimestamp: sensor.pairingTimestamp, fram: fram)
                            
                            if enableStreaming {
                                let streamingCmd = self.nfcCommand(.enableStreaming, unlockCode: self.unlockCode, patchInfo: patchInfo, sensorUID: sensorUID)
                                let streaminResponse = try await tag.customCommand(requestFlags: .highDataRate, customCommandCode: Int(streamingCmd.code), customRequestParameters: streamingCmd.parameters)
                                let streamingEnabled = streaminResponse.count == 6
                                
                                guard streamingEnabled else {
                                    returnWithError(LibrePairingError.streamingNotEnabled)
                                    return
                                }
                            }
                            
                            returnWithResult(isPaired: true, sensor: sensor, readings: readings.history + readings.trend)
                            return
                        }
                        
                    case .libre3:
                        guard patchInfo.count == 28 else {
                            break
                        }
                        
                        let sensor = Sensor.libre3Sensor(uuid: sensorUID, patchInfo: patchInfo)

                        returnWithResult(isPaired: true, sensor: sensor, readings: [])
                        return
                        
                    default:
                        break
                    }

                    returnWithError(LibrePairingError.unsupportedSensor(type: type.localizedDescription))
                }
            }
        }
    }

    // MARK: Private

    private let retryCount = 5
    private var enableStreaming: Bool = false
    private var activeContinuation: CheckedContinuation<LibrePairingResult, Error>?
    private var session: NFCTagReaderSession?
    private let nfcQueue = DispatchQueue(label: "libre-direct.nfc-queue")
    private let unlockCode: UInt32 = 42

    private func returnWithError(_ error: LibrePairingError) {
        DirectLog.error("\(error)")

        session?.alertMessage = error.errorDescription ?? error.description
        session?.invalidate()

        activeContinuation?.resume(throwing: error)
        activeContinuation = nil
    }

    private func returnWithResult(isPaired: Bool, sensor: Sensor, readings: [SensorReading]) {
        session?.alertMessage = LocalizedString("Scan completed successfully")
        session?.invalidate()

        activeContinuation?.resume(returning: LibrePairingResult(isPaired: isPaired, sensor: sensor, readings: readings))
        activeContinuation = nil
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
            y = UInt16(patchInfo[4 ... 5]) ^ UInt16(b[1], b[0])
        } else {
            y = 0x1B6A
        }

        if !b.isEmpty {
            parameters += b
        }

        if code.rawValue < 0x20 {
            let d = Libre2EUtility.usefulFunction(uuid: sensorUID, x: UInt16(code.rawValue), y: y)
            parameters += d
        }

        return NFCCommand(code: 0xA1, parameters: parameters)
    }
}

struct LibrePairingResult {
    let isPaired: Bool
    let sensor: Sensor
    let readings: [SensorReading]
}

enum LibrePairingError: Error {
    case nfcNotAvailable
    case noTagFound
    case noIsoTagFound
    case failedToConnect
    case invalidPatchInfo
    case unsupportedSensor(type: String)
    case failedToRead
    case streamingNotEnabled
    case invalidBuffer
    case unknownError
}

extension LibrePairingError: CustomStringConvertible {
    var description: String {
        switch self {
        case .unsupportedSensor(type: let type):
            return "Unsupported sensor: \(type)"

        default:
            return "Retry pairing"
        }
    }
}

extension LibrePairingError: LocalizedError {
    var errorDescription: String? {
        return LocalizedString(description)
    }
}

private struct NFCCommand {
    let code: UInt8
    let parameters: Data
}

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

#else

class LibreNFC: NSObject {
    func readSensor(enableStreaming: Bool) async throws -> LibrePairingResult {
        fatalError("libre pairing is only available for nfc devices")
    }
}

#endif
