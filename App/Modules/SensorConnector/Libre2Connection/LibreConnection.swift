//
//  LibreConnection.swift
//  GlucoseDirectApp
//

import Combine
import Foundation

// MARK: - LibreConnection

class LibreConnection: SensorConnectionProtocol, IsSensor {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<DirectAction, DirectError>) {
        DirectLog.info("init")

        self.subject = subject
    }

    // MARK: Internal

    weak var subject: PassthroughSubject<DirectAction, DirectError>?

    func pairConnection() {
        DirectLog.info("PairSensor")

        UserDefaults.standard.libreUnlockCount = 0

        sendUpdate(connectionState: .pairing)
        pairingService?.readSensor()
    }

    func connectConnection(sensor: Sensor, sensorInterval: Int) {
        guard let subject = subject else {
            return
        }

        if let sensorType = self.sensor?.type, sensorType != sensor.type {
            bluetoothService = nil
        }

        if bluetoothService == nil {
            if sensor.type == .libre2EU {
                bluetoothService = Libre2Connection(subject: subject)
            } else {
                return
            }
        }

        bluetoothService?.connectConnection(sensor: sensor, sensorInterval: sensorInterval)
    }

    func disconnectConnection() {
        bluetoothService?.disconnectConnection()
    }

    // MARK: Private

    private var sensor: Sensor?

    private lazy var pairingService: LibrePairing? = {
        if let subject = subject {
            return LibrePairing(subject: subject)
        }

        return nil
    }()

    private var bluetoothService: SensorBluetoothConnection?
}

extension UserDefaults {
    private enum Keys: String {
        case libreUnlockCount = "libre-direct.libre2.unlock-count"
    }

    var libreUnlockCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.libreUnlockCount.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.libreUnlockCount.rawValue)
        }
    }
}
