//
//  SensorBLEConnection.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - SensorBLEConnectionBase

class SensorBLEConnectionBase: NSObject, SensorBLEConnection, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<AppAction, AppError>, serviceUuid: CBUUID) {
        AppLog.info("init")

        super.init()

        self.subject = subject
        self.serviceUuid = serviceUuid
        self.manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    deinit {
        AppLog.info("deinit")

        managerQueue.sync {
            disconnect()
        }
    }

    // MARK: Internal

    var serviceUuid: CBUUID!
    var manager: CBCentralManager!

    let managerQueue = DispatchQueue(label: "libre-direct.sensor-ble-connection.queue")
    weak var subject: PassthroughSubject<AppAction, AppError>?

    var stayConnected = false
    var sensor: Sensor?
    var sensorInterval = 1
    var connectionMode: ConnectionMode = .unknown

    var peripheralName: String {
        preconditionFailure("This property must be overridden")
    }

    var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self

            UserDefaults.standard.sensorPeripheralUuid = peripheral?.identifier.uuidString
        }
    }

    func pairSensor() {
        AppLog.info("PairSensor")

        UserDefaults.standard.sensorPeripheralUuid = nil

        sendUpdate(connectionState: .pairing)

        managerQueue.async {
            self.find()
        }
    }

    func connectSensor(sensor: Sensor, sensorInterval: Int) {
        AppLog.info("ConnectSensor: \(sensor)")

        self.sensor = sensor
        self.sensorInterval = sensorInterval

        managerQueue.async {
            self.find()
        }
    }

    func disconnectSensor() {
        AppLog.info("DisconnectSensor")

        managerQueue.sync {
            self.disconnect()
        }
    }

    func find() {
        AppLog.info("find")

        setStayConnected(stayConnected: true)

        guard manager.state == .poweredOn else {
            AppLog.error("Guard: manager.state \(manager.state.rawValue) is not .poweredOn")
            return
        }

        /* if let connectedPeripheral = manager.retrieveConnectedPeripherals(withServices: [serviceUuid]).first(where: { $0.name?.lowercased().starts(with: peripheralName) ?? false }) {
             AppLog.info("Connect from retrievePeripherals")

             connectionMode = .alreadyConnectedDevice
             connect(connectedPeripheral)
         } else */

        if let peripheralUuidString = UserDefaults.standard.sensorPeripheralUuid,
           let peripheralUuid = UUID(uuidString: peripheralUuidString),
           let retrievedPeripheral = manager.retrievePeripherals(withIdentifiers: [peripheralUuid]).first,
           checkRetrievedPeripheral(peripheral: retrievedPeripheral)
        {
            AppLog.info("Connect from retrievePeripherals")

            connectionMode = .knownDevice
            connect(retrievedPeripheral)
        } else {
            AppLog.info("Scan for peripherals")

            connectionMode = .foundDevice
            scan()
        }
    }

    func scan() {
        AppLog.info("scan")

        sendUpdate(connectionState: .scanning)
        manager.scanForPeripherals(withServices: [serviceUuid], options: nil)
    }

    func disconnect() {
        AppLog.info("Disconnect")

        setStayConnected(stayConnected: false)

        if manager.isScanning {
            manager.stopScan()
        }

        if let peripheral = peripheral {
            manager.cancelPeripheralConnection(peripheral)
            self.peripheral = nil
        }

        sendUpdate(connectionState: .disconnected)
        sensor = nil
    }

    func connect() {
        AppLog.info("Connect")

        if let peripheral = peripheral {
            connect(peripheral)
        } else {
            find()
        }
    }

    func connect(_ peripheral: CBPeripheral) {
        AppLog.info("Connect: \(peripheral)")

        if self.peripheral != peripheral {
            self.peripheral = peripheral
        }

        manager.connect(peripheral, options: nil)
        sendUpdate(connectionState: .connecting)
    }

    func resetBuffer() {
        preconditionFailure("This method must be overridden")
    }

    func setStayConnected(stayConnected: Bool) {
        AppLog.info("StayConnected: \(stayConnected.description)")
        self.stayConnected = stayConnected
    }

    func checkRetrievedPeripheral(peripheral: CBPeripheral) -> Bool {
        preconditionFailure("This property must be overridden")
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch manager.state {
        case .poweredOff:
            sendUpdate(connectionState: .powerOff)

        case .poweredOn:
            sendUpdate(connectionState: .disconnected)

            guard stayConnected else {
                break
            }

            find()
        default:
            sendUpdate(connectionState: .unknown)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        AppLog.info("Peripheral: \(peripheral)")

        guard peripheral.name?.lowercased().starts(with: peripheralName) ?? false else {
            return
        }

        manager.stopScan()
        connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        AppLog.info("Peripheral: \(peripheral), didFailToConnect")

        sendUpdate(connectionState: .disconnected)
        sendUpdate(error: error)

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        AppLog.info("Peripheral: \(peripheral), didDisconnectPeripheral")

        sendUpdate(connectionState: .disconnected)
        sendUpdate(error: error)

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        AppLog.info("Peripheral: \(peripheral)")

        resetBuffer()

        sendUpdate(connectionState: .connected)
        peripheral.discoverServices([serviceUuid])
    }
}

// MARK: - ConnectionMode

enum ConnectionMode {
    case unknown
    case knownDevice
    case alreadyConnectedDevice
    case foundDevice
}

extension UserDefaults {
    private enum Keys: String {
        case devicePeripheralUuid = "libre-direct.sensor-ble-connection.peripheral-uuid"
    }

    var sensorPeripheralUuid: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.devicePeripheralUuid.rawValue)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.setValue(newValue, forKey: Keys.devicePeripheralUuid.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.devicePeripheralUuid.rawValue)
            }
        }
    }
}
