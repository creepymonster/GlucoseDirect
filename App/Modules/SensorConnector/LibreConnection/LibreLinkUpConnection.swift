//
//  LibreLinkUpConnection.swift
//  GlucoseDirectApp
//

import Combine
import CoreBluetooth
import Foundation
import SwiftUI

// MARK: - LibreLinkUpConnection

class LibreLinkUpConnection: SensorBluetoothConnection, IsSensor {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<DirectAction, DirectError>) {
        super.init(subject: subject, serviceUUID: CBUUID(string: "089810CC-EF89-11E9-81B4-2A2AE2DBCCE4"))
    }

    // MARK: Internal

    override var peripheralName: String {
        ""
    }

    override func resetBuffer() {}

    override func checkRetrievedPeripheral(peripheral: CBPeripheral) -> Bool {
        return true
    }

    override func pairConnection() {
        Task {
            do {
                try await loginIfNeeded(forceLogin: true)
            } catch {
                sendUpdate(error: error)
            }
        }
    }

    override func find() {
        DirectLog.info("Find")

        guard manager != nil else {
            DirectLog.error("Guard: manager is nil")
            return
        }

        guard manager.state == .poweredOn else {
            DirectLog.error("Guard: manager.state \(manager.state.rawValue) is not .poweredOn")
            return
        }

        if let connectedPeripheral = manager.retrieveConnectedPeripherals(withServices: [serviceUUID]).first {
            DirectLog.info("Connect from retrievePeripherals")

            peripheralType = .connectedPeripheral
            connect(connectedPeripheral)

        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                self.find()
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        DirectLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                DirectLog.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        DirectLog.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                DirectLog.info("Characteristic Uuid: \(characteristic.uuid.description)")

                if characteristic.uuid == oneMinuteReadingUUID {
                    oneMinuteReadingCharacteristic = characteristic
                }
            }
        }

        if let characteristic = oneMinuteReadingCharacteristic {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        sendUpdate(error: error)

        guard let value = characteristic.value else {
            return
        }

        let sleepFactor: UInt64 = value.count == 15
            ? 0
            : 1

        if lastLogin == nil, sleepFactor == 1 {
            return
        }

        Task {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000 * 30 * sleepFactor)
                try await update()
            } catch {
                sendUpdate(error: error)
            }
        }
    }

    override func getConfiguration() -> [SensorConnectionConfigurationOption]? {
        return [
            SensorConnectionConfigurationOption(id: UserDefaults.Keys.email.rawValue, name: LocalizedString("LibreLinkUp email"), value: Binding(
                get: { UserDefaults.standard.email },
                set: { UserDefaults.standard.email = $0 }
            ), isSecret: false),
            SensorConnectionConfigurationOption(id: UserDefaults.Keys.password.rawValue, name: LocalizedString("LibreLinkUp password"), value: Binding(
                get: { UserDefaults.standard.password },
                set: { UserDefaults.standard.password = $0 }
            ), isSecret: true),
        ]
    }

    // MARK: Private

    private var lastLogin: LibreLinkLogin?
    private let oneMinuteReadingUUID = CBUUID(string: "0898177A-EF89-11E9-81B4-2A2AE2DBCCE4")
    private var oneMinuteReadingCharacteristic: CBCharacteristic?
    private let requestHeaders = [
        "User-Agent": "Mozilla/5.0",
        "Content-Type": "application/json",
        "product": "llu.ios",
        "version": "4.3.0",
        "Accept-Encoding": "gzip, deflate, br",
        "Connection": "keep-alive",
        "Pragma": "no-cache",
        "Cache-Control": "no-cache",
    ]

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy h:mm:ss a"
        return formatter
    }()

    private lazy var jsonDecoder: JSONDecoder? = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        return decoder
    }()

    private func update() async throws {
        let fetch = try await fetch()

        guard let sensorAge = fetch.data?.connection?.sensor?.age ?? fetch.data?.activeSensors?.first?.sensor?.age else {
            throw LibreLinkError.missingData
        }

        guard let trendData = fetch.data?.connection?.glucoseMeasurement else {
            throw LibreLinkError.missingData
        }

        // guard let historyData = fetch.data?.graphData else {
        //     throw LibreLinkError.missingData
        // }

        sendUpdate(age: sensorAge, state: .ready)

        let trend = [
            SensorReading.createGlucoseReading(timestamp: trendData.timestamp, glucoseValue: trendData.value),
        ]

        // let history = historyData.map {
        //     SensorReading.createGlucoseReading(timestamp: $0.timestamp, glucoseValue: $0.value)
        // }

        // sendUpdate(readings: history + trend)
        sendUpdate(readings: trend)
    }

    private func loginIfNeeded(forceLogin: Bool = false) async throws {
        if forceLogin || lastLogin == nil || (lastLogin?.authExpires ?? Date()) <= Date() || (lastLogin?.authToken.count ?? 0) == 0 {
            let login = try await login()

            guard let userID = login.data?.user?.id,
                  let userCountry = login.data?.user?.country,
                  let authToken = login.data?.authTicket?.token,
                  let authExpires = login.data?.authTicket?.expires,
                  !userCountry.isEmpty, !authToken.isEmpty
            else {
                throw LibreLinkError.invalidCredentials
            }

            DirectLog.info("LibreLinkUp login, userID: \(userID)")
            DirectLog.info("LibreLinkUp login, userCountry: \(userCountry)")
            DirectLog.info("LibreLinkUp login, authToken: \(authToken)")
            DirectLog.info("LibreLinkUp login, authExpires: \(authExpires)")

            let connect = try await connect(userCountry: userCountry, authToken: authToken)

            guard let patientID = connect.data?.first?.patientID else {
                throw LibreLinkError.invalidCredentials
            }

            DirectLog.info("LibreLinkUp login, patientID: \(patientID)")

            lastLogin = LibreLinkLogin(userID: userID, patientID: patientID, userCountry: userCountry, authToken: authToken, authExpires: authExpires)
        }
    }

    private func login() async throws -> LibreLinkResponse<LibreLinkResponseLogin> {
        DirectLog.info("LibreLinkUp login")

        guard let url = URL(string: "https://api.libreview.io/llu/auth/login") else {
            throw LibreLinkError.invalidURL
        }

        guard let credentials = try? JSONSerialization.data(withJSONObject: [
            "email": UserDefaults.standard.email,
            "password": UserDefaults.standard.password,
        ]) else {
            throw LibreLinkError.serializationError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = credentials

        for (header, value) in requestHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        DirectLog.info("LibreLinkUp login, response: \(String(data: data, encoding: String.Encoding.utf8))")

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw LibreLinkError.invalidCredentials
        }

        return try decode(LibreLinkResponse<LibreLinkResponseLogin>.self, data: data)
    }

    private func connect(userCountry: String, authToken: String) async throws -> LibreLinkResponse<[LibreLinkResponseConnect]> {
        DirectLog.info("LibreLinkUp connect")

        guard let url = URL(string: "https://api-\(userCountry).libreview.io/llu/connections") else {
            throw LibreLinkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        for (header, value) in requestHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        DirectLog.info("LibreLinkUp connect, response: \(String(data: data, encoding: String.Encoding.utf8))")

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw LibreLinkError.notAuthenticated
        }

        return try decode(LibreLinkResponse<[LibreLinkResponseConnect]>.self, data: data)
    }

    private func fetch() async throws -> LibreLinkResponse<LibreLinkResponseFetch> {
        DirectLog.info("LibreLinkUp fetch")

        try await loginIfNeeded()

        guard let lastLogin = lastLogin else {
            throw LibreLinkError.missingLoginSession
        }

        guard let url = URL(string: "https://api-\(lastLogin.userCountry).libreview.io/llu/connections/\(lastLogin.patientID)/graph") else {
            throw LibreLinkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(lastLogin.authToken)", forHTTPHeaderField: "Authorization")

        for (header, value) in requestHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        DirectLog.info("LibreLinkUp fetch, response: \(String(data: data, encoding: String.Encoding.utf8))")

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw LibreLinkError.notAuthenticated
        }

        return try decode(LibreLinkResponse<LibreLinkResponseFetch>.self, data: data)
    }

    private func decode<T: Decodable>(_ type: T.Type, data: Data) throws -> T {
        guard let jsonDecoder = jsonDecoder else {
            throw LibreLinkError.decoderError
        }

        return try jsonDecoder.decode(T.self, from: data)
    }
}

private extension UserDefaults {
    enum Keys: String {
        case email = "libre-direct.libre-link-up.email"
        case password = "libre-direct.libre-link-up.password"
    }

    var email: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.email.rawValue) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.email.rawValue)
        }
    }

    var password: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.password.rawValue) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.password.rawValue)
        }
    }
}

// MARK: - LibreLinkResponse

private struct LibreLinkResponse<T: Codable>: Codable {
    let status: Int
    let data: T?
}

// MARK: - LibreLinkResponseLogin

private struct LibreLinkResponseLogin: Codable {
    let user: LibreLinkResponseUser?
    let authTicket: LibreLinkResponseAuthentication?
}

// MARK: - LibreLinkResponseConnect

private struct LibreLinkResponseConnect: Codable {
    enum CodingKeys: String, CodingKey { case patientID = "patientId" }

    let patientID: String?
}

// MARK: - LibreLinkResponseFetch

private struct LibreLinkResponseFetch: Codable {
    let connection: LibreLinkResponseConnection?
    let activeSensors: [LibreLinkResponseActiveSensors]?
    // let graphData: [LibreLinkResponseGlucose]?
}

// MARK: - LibreLinkResponseConnection

private struct LibreLinkResponseConnection: Codable {
    let sensor: LibreLinkResponseSensor?
    let glucoseMeasurement: LibreLinkResponseGlucose?
}

// MARK: - LibreLinkResponseActiveSensors

private struct LibreLinkResponseActiveSensors: Codable {
    let sensor: LibreLinkResponseSensor?
}

// MARK: - LibreLinkResponseSensor

private struct LibreLinkResponseSensor: Codable {
    enum CodingKeys: String, CodingKey { case serial = "sn", activation = "a" }

    let serial: String
    let activation: Double

    var age: Int {
        let activationDate = Date(timeIntervalSince1970: activation)
        return Calendar.current.dateComponents([.minute], from: activationDate, to: Date()).minute ?? 0
    }
}

// MARK: - LibreLinkResponseGlucose

private struct LibreLinkResponseGlucose: Codable {
    enum CodingKeys: String, CodingKey { case timestamp = "Timestamp", value = "ValueInMgPerDl" }

    let timestamp: Date
    let value: Double
}

// MARK: - LibreLinkResponseUser

private struct LibreLinkResponseUser: Codable {
    let id: String
    let country: String
}

// MARK: - LibreLinkResponseAuthentication

private struct LibreLinkResponseAuthentication: Codable {
    let token: String
    let expires: Double
}

// MARK: - LibreLinkLogin

private struct LibreLinkLogin {
    // MARK: Lifecycle

    init(userID: String, patientID: String, userCountry: String, authToken: String, authExpires: Double) {
        self.userID = userID
        self.patientID = patientID

        if ["ae", "ap", "au", "de", "eu", "fr", "jp", "us"].contains(userCountry.lowercased()) {
            self.userCountry = userCountry.lowercased()
        } else {
            self.userCountry = "eu"
        }

        self.authToken = authToken
        self.authExpires = Date(timeIntervalSince1970: authExpires)
    }

    // MARK: Internal

    let userID: String
    let patientID: String
    let userCountry: String
    let authToken: String
    let authExpires: Date
}

// MARK: - LibreLinkError

private enum LibreLinkError: Error {
    case invalidURL
    case serializationError
    case missingLoginSession
    case invalidCredentials
    case missingCredentials
    case notAuthenticated
    case decoderError
    case missingData
    case parsingError
}

// MARK: CustomStringConvertible

extension LibreLinkError: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidURL:
            return "Invalid url"
        case .serializationError:
            return "Serialization error"
        case .missingLoginSession:
            return "Missing login session"
        case .invalidCredentials:
            return "Invalid credentials"
        case .missingCredentials:
            return "Missing credentials"
        case .notAuthenticated:
            return "Not authenticated"
        case .decoderError:
            return "Decoder error"
        case .missingData:
            return "Missing data"
        case .parsingError:
            return "Parsing error"
        }
    }
}

// MARK: LocalizedError

extension LibreLinkError: LocalizedError {
    var errorDescription: String? {
        return LocalizedString(description)
    }
}
