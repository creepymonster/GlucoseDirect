//
//  LibreLinkPairing.swift
//  GlucoseDirect
//
//  Special thanks to: guidos
//

import Combine
import Foundation

#if canImport(CoreNFC)
import CoreNFC

class LibreLinkPairing: NSObject, NFCTagReaderSessionDelegate {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<DirectAction, DirectError>) {
        self.subject = subject
    }

    // MARK: Internal

    func readSensor() {
        guard subject != nil else {
            logErrorAndDisconnect("Pairing, subject is nil")
            return
        }

        if NFCTagReaderSession.readingAvailable {
            session = NFCTagReaderSession(pollingOption: .iso15693, delegate: self, queue: nfcQueue)
            session?.alertMessage = LocalizedString("Hold the top edge of your iPhone close to the sensor.")
            session?.begin()
        }
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError, readerError.code != .readerSessionInvalidationErrorUserCanceled {
            session.invalidate(errorMessage: "Connection failure: \(readerError.localizedDescription)")

            logErrorAndDisconnect("Reader session didInvalidateWithError: \(readerError.localizedDescription))")
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Task {
            guard let firstTag = tags.first else {
                logErrorAndDisconnect("No tag found")
                return
            }

            guard case .iso15693(let tag) = firstTag else {
                logErrorAndDisconnect("No ISO15693 tag found")
                return
            }

            do {
                try await session.connect(to: firstTag)
            } catch {
                logErrorAndDisconnect("Failed to connect to tag")
                return
            }

            let sensorUID = Data(tag.identifier.reversed())
            var patchInfo = Data()

            do {
                patchInfo = try await tag.customCommand(requestFlags: .highDataRate, customCommandCode: 0xA1, customRequestParameters: Data())
            } catch {
                logErrorAndDisconnect("Invalid patchInfo")
                return
            }

            guard patchInfo.count >= 6 else {
                logErrorAndDisconnect("Invalid patchInfo")
                return
            }

            let type = SensorType(patchInfo)
            guard type == .libre2EU || type == .libre1 || type == .libreUS14day else {
                logErrorAndDisconnect("Unsupported: \(type.localizedDescription)", showToUser: true)
                return
            }

            let blocks = 43
            let requestBlocks = 3

            let requests = Int(ceil(Double(blocks) / Double(requestBlocks)))
            let remainder = blocks % requestBlocks
            var dataArray = [Data](repeating: Data(), count: blocks)

            for i in 0 ..< requests {
                let requestFlags: NFCISO15693RequestFlag = [.highDataRate, .address]
                let blockRange = NSRange(UInt8(i * requestBlocks) ... UInt8(i * requestBlocks + (i == requests - 1 ? (remainder == 0 ? requestBlocks : remainder) : requestBlocks) - (requestBlocks > 1 ? 1 : 0)))

                var failedRead: Bool
                var failedRetries = 5

                repeat {
                    failedRead = false
                    failedRetries -= 1

                    do {
                        let blockArray = try await tag.readMultipleBlocks(requestFlags: requestFlags, blockRange: blockRange)
                        for j in 0 ..< blockArray.count {
                            dataArray[i * requestBlocks + j] = blockArray[j]
                        }
                    } catch {
                        failedRead = true
                    }
                } while failedRead && failedRetries > 0

                if failedRead {
                    logErrorAndDisconnect("Failed to read multiple tags")
                    return
                }

                if i == requests - 1 {
                    DirectLog.info("Create fram")

                    var rxBuffer = Data()
                    for (_, data) in dataArray.enumerated() {
                        if !data.isEmpty {
                            rxBuffer.append(data)
                        }
                    }

                    guard rxBuffer.count >= 344 else {
                        logErrorAndDisconnect("Invalid rxBuffer")
                        return
                    }

                    guard let fram = type == .libre1
                        ? rxBuffer
                        : Libre2EUtility.decryptFRAM(uuid: sensorUID, patchInfo: patchInfo, fram: rxBuffer)
                    else {
                        logErrorAndDisconnect("Cannot create useable fram")
                        return
                    }

                    DirectLog.info("Create sensor")
                    let sensor = Sensor.libreStyleSensor(uuid: sensorUID, patchInfo: patchInfo, fram: fram)

                    DirectLog.info("Sensor: \(sensor)")
                    DirectLog.info("Sensor, age: \(sensor.age)")
                    DirectLog.info("Sensor, lifetime: \(sensor.lifetime)")

                    if type == .libre1 || type == .libreUS14day {
                        session.invalidate()

                        self.subject?.send(.setSensor(sensor: sensor))
                        self.subject?.send(.setConnectionPaired(isPaired: false))

                        if sensor.age >= sensor.lifetime {
                            self.subject?.send(.setSensorState(sensorAge: sensor.age, sensorState: .expired))

                        } else if sensor.age > sensor.warmupTime {
                            let readings = LibreUtility.parseFRAM(calibration: sensor.factoryCalibration, pairingTimestamp: sensor.pairingTimestamp, fram: fram)

                            self.subject?.send(.setSensorState(sensorAge: sensor.age, sensorState: sensor.state))
                            self.subject?.send(.addSensorReadings(sensorSerial: sensor.serial ?? "", readings: readings.history + readings.trend))

                        } else if sensor.age <= sensor.warmupTime {
                            self.subject?.send(.setSensorState(sensorAge: sensor.age, sensorState: sensor.state))
                        }
                    } else {
                        session.invalidate()

                        self.subject?.send(.setSensor(sensor: sensor))
                        self.subject?.send(.setConnectionState(connectionState: .disconnected))
                        self.subject?.send(.setConnectionPaired(isPaired: true))

                        if sensor.age >= sensor.lifetime {
                            self.subject?.send(.setSensorState(sensorAge: sensor.age, sensorState: .expired))

                        } else if sensor.age > sensor.warmupTime {
                            let readings = LibreUtility.parseFRAM(calibration: sensor.factoryCalibration, pairingTimestamp: sensor.pairingTimestamp, fram: fram)

                            self.subject?.send(.setSensorState(sensorAge: sensor.age, sensorState: sensor.state))
                            self.subject?.send(.addSensorReadings(sensorSerial: sensor.serial ?? "", readings: readings.history + readings.trend))

                        } else if sensor.age <= sensor.warmupTime {
                            self.subject?.send(.setSensorState(sensorAge: sensor.age, sensorState: sensor.state))
                        }
                    }
                }
            }
        }
    }

    // MARK: Private

    private var session: NFCTagReaderSession?
    private weak var subject: PassthroughSubject<DirectAction, DirectError>?

    private let nfcQueue = DispatchQueue(label: "libre-direct.nfc-queue")
    private let unlockCode: UInt32 = 42

    private func logErrorAndDisconnect(_ message: String, showToUser: Bool = false) {
        DirectLog.error(message)

        session?.invalidate()

        subject?.send(.setConnectionError(errorMessage: showToUser ? message : LocalizedString("Retry pairing"), errorTimestamp: Date(), errorIsCritical: false))
        subject?.send(.setConnectionState(connectionState: .disconnected))
    }
}

#else

class LibreLinkPairing: NSObject {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<DirectAction, DirectError>) {}

    // MARK: Internal

    func readSensor() {}
}

#endif
