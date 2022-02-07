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

    init(subject: PassthroughSubject<AppAction, AppError>, serviceUUID: CBUUID) {
        AppLog.info("init")

        super.init()

        self.subject = subject
        self.serviceUUID = serviceUUID
        self.manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    deinit {
        AppLog.info("deinit")

        managerQueue.sync {
            disconnect()
        }
    }

    // MARK: Internal

    var serviceUUID: CBUUID!
    var manager: CBCentralManager!

    let managerQueue = DispatchQueue(label: "libre-direct.sensor-ble-connection.queue")
    weak var subject: PassthroughSubject<AppAction, AppError>?

    var stayConnected = false
    var sensor: Sensor?
    var sensorInterval = 1

    var peripheralName: String {
        preconditionFailure("This property must be overridden")
    }

    var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self

            if let sensorPeripheralUUID = peripheral?.identifier.uuidString {
                UserDefaults.standard.sensorPeripheralUUID = sensorPeripheralUUID
            }
        }
    }

    func pairSensor() {
        AppLog.info("PairSensor")

        sendUpdate(connectionState: .pairing)

        managerQueue.async {
            self.find()
        }
    }

    func connectSensor(sensor: Sensor, sensorInterval: Int) {
        AppLog.info("ConnectSensor: \(sensor)")

        self.sensor = sensor
        self.sensorInterval = sensorInterval

        setStayConnected(stayConnected: true)

        managerQueue.async {
            self.find()
        }
    }

    func disconnectSensor() {
        AppLog.info("DisconnectSensor")

        setStayConnected(stayConnected: false)

        managerQueue.sync {
            self.disconnect()
        }
    }

    func find() {
        AppLog.info("Find")
        
        guard manager != nil else {
            AppLog.error("Guard: manager is nil")
            return
        }

        guard manager.state == .poweredOn else {
            AppLog.error("Guard: manager.state \(manager.state.rawValue) is not .poweredOn")
            return
        }

        if let peripheralUUIDString = UserDefaults.standard.sensorPeripheralUUID,
           let peripheralUUID = UUID(uuidString: peripheralUUIDString),
           let retrievedPeripheral = manager.retrievePeripherals(withIdentifiers: [peripheralUUID]).first,
           checkRetrievedPeripheral(peripheral: retrievedPeripheral)
        {
            AppLog.info("Connect from retrievePeripherals")
            connect(retrievedPeripheral)
        } else {
            AppLog.info("Scan for peripherals")
            scan()
        }
    }

    func scan() {
        AppLog.info("scan")
        
        guard manager != nil else {
            AppLog.error("Guard: manager is nil")
            return
        }

        sendUpdate(connectionState: .scanning)
        manager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }

    func disconnect() {
        AppLog.info("Disconnect")
        
        guard manager != nil else {
            AppLog.error("Guard: manager is nil")
            return
        }

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

    func connect(_ peripheral: CBPeripheral) {
        AppLog.info("Connect: \(peripheral)")
        
        guard manager != nil else {
            AppLog.error("Guard: manager is nil")
            return
        }

        self.peripheral = peripheral

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
        guard manager != nil else {
            AppLog.error("Guard: manager is nil")
            return
        }
        
        if let manager = manager {
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
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        AppLog.info("Peripheral: \(peripheral)")
        
        guard manager != nil else {
            AppLog.error("Guard: manager is nil")
            return
        }

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

        connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        AppLog.info("Peripheral: \(peripheral), didDisconnectPeripheral")

        sendUpdate(connectionState: .disconnected)
        sendUpdate(error: error)

        guard stayConnected else {
            return
        }

        connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        AppLog.info("Peripheral: \(peripheral)")

        resetBuffer()

        sendUpdate(connectionState: .connected)
        peripheral.discoverServices([serviceUUID])
    }
}
