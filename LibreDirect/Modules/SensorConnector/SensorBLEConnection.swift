//
//  SensorBLEConnection.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - SensorBLEConnection

class SensorBLEConnection: NSObject, SensorBluetoothConnection, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<AppAction, AppError>, serviceUuid: CBUUID) {
        AppLog.info("init")

        self.subject = subject
        self.serviceUuid = serviceUuid
    }

    deinit {
        AppLog.info("deinit")

        managerQueue.sync {
            disconnect()
        }
    }

    // MARK: Internal

    var serviceUuid: CBUUID
    lazy var manager: CBCentralManager = {
        CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }()
    
    let managerQueue = DispatchQueue(label: "libre-direct.sensor-ble-connection.queue")
    weak var subject: PassthroughSubject<AppAction, AppError>?

    var stayConnected = false
    var sensor: Sensor?

    var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self

            UserDefaults.standard.peripheralUuid = peripheral?.identifier.uuidString
        }
    }

    func pairSensor() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        AppLog.info("PairSensor")

        UserDefaults.standard.peripheralUuid = nil

        sendUpdate(connectionState: .pairing)

        managerQueue.async {
            self.find()
        }
    }

    func connectSensor(sensor: Sensor) {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        AppLog.info("ConnectSensor: \(sensor)")

        self.sensor = sensor

        managerQueue.async {
            self.find()
        }
    }

    func disconnectSensor() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        AppLog.info("DisconnectSensor")

        managerQueue.sync {
            self.disconnect()
        }
    }

    func find() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("find")

        setStayConnected(stayConnected: true)

        guard manager.state == .poweredOn else {
            AppLog.error("Guard: manager.state \(manager.state.rawValue) is not .poweredOn")
            return
        }

        if let peripheralUuidString = UserDefaults.standard.peripheralUuid,
           let peripheralUuid = UUID(uuidString: peripheralUuidString),
           let retrievedPeripheral = manager.retrievePeripherals(withIdentifiers: [peripheralUuid]).first
        {
            AppLog.info("Connect from retrievePeripherals")
            connect(retrievedPeripheral)
        } else {
            AppLog.info("Scan for peripherals")
            scan()
        }
    }

    func scan() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("scan")

        sendUpdate(connectionState: .scanning)
        manager.scanForPeripherals(withServices: [serviceUuid], options: nil)
    }

    func disconnect() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
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
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Connect")

        if let peripheral = peripheral {
            connect(peripheral)
        } else {
            find()
        }
    }

    func connect(_ peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
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

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

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

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral), didFailToConnect")

        sendUpdate(connectionState: .disconnected)
        sendUpdate(error: error)

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral), didDisconnectPeripheral")

        sendUpdate(connectionState: .disconnected)
        sendUpdate(error: error)

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Peripheral: \(peripheral)")

        resetBuffer()

        sendUpdate(connectionState: .connected)
        peripheral.discoverServices([serviceUuid])
    }
}

extension UserDefaults {
    private enum Keys: String {
        case devicePeripheralUuid = "libre-direct.sensor-ble-connection.peripheral-uuid"
    }

    var peripheralUuid: String? {
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
