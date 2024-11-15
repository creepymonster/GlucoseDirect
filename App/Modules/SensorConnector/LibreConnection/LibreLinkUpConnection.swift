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
    }

    override func connectConnection(sensor: Sensor, sensorInterval: Int) {
        DirectLog.info("ConnectSensor: \(sensor)")
        DirectLog.info("ConnectSensor, throttleDelay: \(throttleDelay)")
        
        self.sensor = sensor
        self.sensorInterval = sensorInterval
        
        setStayConnected(stayConnected: true)

        Task {
            do {
                self.lastLogin = nil

                try await self.processLogin()

                self.managerQueue.async {
                    self.find()
                }
            } catch {
                self.sendUpdate(error: error)
            }
        }
    }

    override func find() {
        guard let manager else {
            DirectLog.error("Guard: manager is nil")
            return
        }

        guard let serviceUUID else {
            DirectLog.error("Guard: serviceUUID is nil")
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
            sendUpdate(connectionState: .scanning)
            
            managerQueue.asyncAfter(deadline: .now() + .seconds(5)) {
                self.find()
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                DirectLog.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
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

        guard value.count == 15 else {
            return
        }

        Task {
            do {
                try await self.processFetch()
            } catch {
                DirectLog.error("Error: \(error)")
            }
        }
    }

    override func getConfiguration(sensor: Sensor) -> [SensorConnectionConfigurationOption] {
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

    private var throttleDelay: Double {
        (Double(sensorInterval) / 1.5) * 60
    }
   
    private var lastLogin: LibreLinkLogin?
    private let oneMinuteReadingUUID = CBUUID(string: "0898177A-EF89-11E9-81B4-2A2AE2DBCCE4")
    private var oneMinuteReadingCharacteristic: CBCharacteristic?
    private let requestHeaders = [
        "User-Agent": "Mozilla/5.0",
        "Content-Type": "application/json",
        "product": "llu.ios",
        "version": "4.12.0",
        "Accept-Encoding": "gzip, deflate, br",
        "Connection": "keep-alive",
        "Pragma": "no-cache",
        "Cache-Control": "no-cache",
    ]

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "M/d/yyyy h:mm:ss a"
        return formatter
    }()

    private lazy var jsonDecoder: JSONDecoder? = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        return decoder
    }()

    private func processLogin(apiRegion: String? = nil) async throws {
        if lastLogin == nil || lastLogin!.authExpires <= Date() {
            DirectLog.info("LibreLinkUp processLogin, starts working, \(Date().debugDescription)")

            var loginResponse = try await login(apiRegion: apiRegion)
            if loginResponse.status == 4 {
                DirectLog.info("LibreLinkUp processLogin, request to accept tou")
                
                guard let authToken = loginResponse.data?.authTicket?.token,
                      !authToken.isEmpty
                else {
                    disconnectConnection()

                    throw LibreLinkError.missingUserOrToken
                }
                
                loginResponse = try await tou(apiRegion: apiRegion, authToken: authToken)
            }

            if let redirect = loginResponse.data?.redirect, let region = loginResponse.data?.region, redirect, !region.isEmpty {
                DirectLog.info("LibreLinkUp processLogin, redirect to userCountry: \(region)")

                try await processLogin(apiRegion: region)
                return
            }

            guard let userID = loginResponse.data?.user?.id,
                  let apiRegion = apiRegion ?? loginResponse.data?.user?.apiRegion,
                  let authToken = loginResponse.data?.authTicket?.token,
                  let authExpires = loginResponse.data?.authTicket?.expires,
                  !apiRegion.isEmpty, !authToken.isEmpty
            else {
                disconnectConnection()

                throw LibreLinkError.missingUserOrToken
            }

            DirectLog.info("LibreLinkUp processLogin, apiRegion: \(apiRegion)")
            DirectLog.info("LibreLinkUp processLogin, authExpires: \(authExpires)")

            let connectResponse = try await connect(userID: userID, apiRegion: apiRegion, authToken: authToken)

            guard let patientID = connectResponse.data?.first(where: { $0.patientID == userID })?.patientID ?? connectResponse.data?.first?.patientID else {
                disconnectConnection()

                throw LibreLinkError.missingPatientID
            }

            DirectLog.info("LibreLinkUp processLogin, patientID: \(patientID)")

            lastLogin = LibreLinkLogin(userID: userID, patientID: patientID, apiRegion: apiRegion, authToken: authToken, authExpires: authExpires)
        }
    }

    private func processFetch() async throws {
        DirectLog.info("LibreLinkUp processFetch, starts working, \(Date().debugDescription)")

        try await processLogin()

        let fetchResponse = try await fetch()

        if let sensorAge = fetchResponse.data?.activeSensors?.first?.sensor?.age ?? fetchResponse.data?.connection?.sensor?.age,
           let sensorSerial = fetchResponse.data?.activeSensors?.first?.sensor?.serial ?? fetchResponse.data?.connection?.sensor?.serial,
           let sensor = sensor
        {
            if sensor.serial != sensorSerial {
                let sensor = Sensor(family: sensor.family, type: sensor.type, region: sensor.region, serial: sensorSerial, state: sensor.state, age: sensorAge, lifetime: sensor.lifetime)
                sendUpdate(sensor: sensor)

                self.sensor = sensor
            }

            if sensorAge >= sensor.lifetime {
                sendUpdate(age: sensorAge, state: .expired)

            } else if sensorAge > sensor.warmupTime {
                sendUpdate(age: sensorAge, state: .ready)

            } else if sensorAge <= sensor.warmupTime {
                sendUpdate(age: sensorAge, state: .starting)
            }
        }

        let data = (fetchResponse.data?.graphData ?? []) + [fetchResponse.data?.connection?.glucoseMeasurement]

        sendUpdate(readings: data.compactMap {
            $0
        }.map {
            SensorReading.createGlucoseReading(timestamp: $0.timestamp, glucoseValue: $0.value)
        })
    }
    
    private func tou(apiRegion: String? = nil, authToken: String) async throws -> LibreLinkResponse<LibreLinkResponseLogin> {
        DirectLog.info("LibreLinkUp tou")

        var urlString: String?
        if let apiRegion = apiRegion {
            urlString = "https://api-\(apiRegion).libreview.io/auth/continue/tou"
        } else {
            urlString = "https://api.libreview.io/auth/continue/tou"
        }

        guard let urlString = urlString else {
            throw LibreLinkError.invalidURL
        }

        guard let url = URL(string: urlString) else {
            throw LibreLinkError.invalidURL
        }

        DirectLog.info("LibreLinkUp tou, url: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        for (header, value) in requestHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        DirectLog.info("LibreLinkUp tou, response: \(String(data: data, encoding: String.Encoding.utf8))")

        if statusCode == 200 {
            return try decode(LibreLinkResponse<LibreLinkResponseLogin>.self, data: data)
        } else if statusCode == 911 {
            throw LibreLinkError.maintenance
        }

        throw LibreLinkError.unknownError
    }

    private func login(apiRegion: String? = nil) async throws -> LibreLinkResponse<LibreLinkResponseLogin> {
        DirectLog.info("LibreLinkUp login")

        guard !UserDefaults.standard.email.isEmpty, !UserDefaults.standard.password.isEmpty else {
            disconnectConnection()

            throw LibreLinkError.missingCredentials
        }

        var urlString: String?
        if let apiRegion = apiRegion {
            urlString = "https://api-\(apiRegion).libreview.io/llu/auth/login"
        } else {
            urlString = "https://api.libreview.io/llu/auth/login"
        }

        guard let urlString = urlString else {
            throw LibreLinkError.invalidURL
        }

        guard let url = URL(string: urlString) else {
            throw LibreLinkError.invalidURL
        }

        DirectLog.info("LibreLinkUp login, url: \(url.absoluteString)")

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
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        DirectLog.info("LibreLinkUp login, response: \(String(data: data, encoding: String.Encoding.utf8))")

        if statusCode == 200 {
            return try decode(LibreLinkResponse<LibreLinkResponseLogin>.self, data: data)
        } else if statusCode == 911 {
            throw LibreLinkError.maintenance
        } else if statusCode == 401 {
            throw LibreLinkError.invalidCredentials
        }

        throw LibreLinkError.unknownError
    }

    private func connect(userID: String, apiRegion: String, authToken: String) async throws -> LibreLinkResponse<[LibreLinkResponseConnect]> {
        DirectLog.info("LibreLinkUp connect")

        guard let url = URL(string: "https://api-\(apiRegion).libreview.io/llu/connections") else {
            throw LibreLinkError.invalidURL
        }

        DirectLog.info("LibreLinkUp connect, url: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userID.toSha256(), forHTTPHeaderField: "Account-Id")

        for (header, value) in requestHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        DirectLog.info("LibreLinkUp connect, response: \(String(data: data, encoding: String.Encoding.utf8))")

        if statusCode == 200 {
            return try decode(LibreLinkResponse<[LibreLinkResponseConnect]>.self, data: data)
        } else if statusCode == 911 {
            throw LibreLinkError.maintenance
        } else if statusCode == 401 {
            throw LibreLinkError.invalidCredentials
        }

        throw LibreLinkError.unknownError
    }

    private func fetch() async throws -> LibreLinkResponse<LibreLinkResponseFetch> {
        DirectLog.info("LibreLinkUp fetch")

        guard let lastLogin = lastLogin else {
            throw LibreLinkError.missingLoginSession
        }

        guard let url = URL(string: "https://api-\(lastLogin.apiRegion).libreview.io/llu/connections/\(lastLogin.patientID)/graph") else {
            throw LibreLinkError.invalidURL
        }

        DirectLog.info("LibreLinkUp fetch, url: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.setValue("Bearer \(lastLogin.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue(lastLogin.userID.toSha256(), forHTTPHeaderField: "Account-Id")

        for (header, value) in requestHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        DirectLog.info("LibreLinkUp fetch, response: \(String(data: data, encoding: String.Encoding.utf8))")

        if statusCode == 200 {
            return try decode(LibreLinkResponse<LibreLinkResponseFetch>.self, data: data)
        } else if statusCode == 911 {
            throw LibreLinkError.maintenance
        } else if statusCode == 401 {
            throw LibreLinkError.invalidCredentials
        }

        throw LibreLinkError.unknownError
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
    let redirect: Bool?
    let region: String?
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
    let graphData: [LibreLinkResponseGlucose]?
}

// MARK: - LibreLinkResponseConnection

private struct LibreLinkResponseConnection: Codable {
    let sensor: LibreLinkResponseSensor?
    let glucoseMeasurement: LibreLinkResponseGlucose?
}

// MARK: - LibreLinkResponseActiveSensors

private struct LibreLinkResponseActiveSensors: Codable {
    let sensor: LibreLinkResponseSensor?
    let device: LibreLinkResponseDevice?
}

// MARK: - LibreLinkResponseDevice

private struct LibreLinkResponseDevice: Codable {
    enum CodingKeys: String, CodingKey { case dtid, version = "v" }

    let dtid: Int
    let version: String
}

// MARK: - LibreLinkResponseSensor

private struct LibreLinkResponseSensor: Codable {
    enum CodingKeys: String, CodingKey { case sn, activation = "a" }

    let sn: String
    let activation: Double

    var age: Int {
        let activationDate = Date(timeIntervalSince1970: activation)
        return Calendar.current.dateComponents([.minute], from: activationDate, to: Date()).minute ?? 0
    }
}

private extension LibreLinkResponseSensor {
    var serial: String {
        return String(sn.dropLast())
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
    let id: String?
    let country: String
}

private extension LibreLinkResponseUser {
    var apiRegion: String {
        if ["ae", "ap", "au", "de", "eu", "fr", "jp", "us"].contains(country.lowercased()) {
            return country.lowercased()
        }
        
        if (country.lowercased() == "gb") {
            return "eu2"
        }

        return "eu"
    }
}

// MARK: - LibreLinkResponseAuthentication

private struct LibreLinkResponseAuthentication: Codable {
    let token: String
    let expires: Double
}

// MARK: - LibreLinkLogin

private struct LibreLinkLogin {
    // MARK: Lifecycle

    init(userID: String, patientID: String, apiRegion: String, authToken: String, authExpires: Double) {
        self.userID = userID
        self.patientID = patientID
        self.apiRegion = apiRegion.lowercased()
        self.authToken = authToken
        self.authExpires = Date(timeIntervalSince1970: authExpires)
    }

    // MARK: Internal

    let userID: String
    let patientID: String
    let apiRegion: String
    let authToken: String
    let authExpires: Date
}

// MARK: - LibreLinkError

private enum LibreLinkError: Error {
    case unknownError
    case maintenance
    case invalidURL
    case serializationError
    case missingLoginSession
    case missingUserOrToken
    case missingPatientID
    case invalidCredentials
    case missingCredentials
    case notAuthenticated
    case decoderError
    case missingData
    case parsingError
    case cannotLock
    case missingStatusCode
}

// MARK: CustomStringConvertible

extension LibreLinkError: CustomStringConvertible {
    var description: String {
        switch self {
        case .unknownError:
            return "Unknown error"
        case .missingStatusCode:
            return "Missing status code"
        case .maintenance:
            return "Maintenance"
        case .invalidURL:
            return "Invalid url"
        case .serializationError:
            return "Serialization error"
        case .missingUserOrToken:
            return "Missing user or token"
        case .missingLoginSession:
            return "Missing login session"
        case .missingPatientID:
            return "Missing patient id"
        case .invalidCredentials:
            return "Invalid credentials (check 'Settings' > 'Connection Settings')"
        case .missingCredentials:
            return "Missing credentials (check 'Settings' > 'Connection Settings')"
        case .notAuthenticated:
            return "Not authenticated"
        case .decoderError:
            return "Decoder error"
        case .missingData:
            return "Missing data"
        case .parsingError:
            return "Parsing error"
        case .cannotLock:
            return "Cannot lock"
        }
    }
}

// MARK: LocalizedError

extension LibreLinkError: LocalizedError {
    var errorDescription: String? {
        return LocalizedString(description)
    }
}
