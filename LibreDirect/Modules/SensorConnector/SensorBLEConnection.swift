//
//  SensorBLEConnection.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - SensorBLEConnection

class SensorBLEConnection: NSObject, SensorConnection, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: Lifecycle

    init(serviceUuid: [CBUUID]) {
        Log.info("init")
        super.init()

        self.serviceUuid = serviceUuid
        self.manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    deinit {
        Log.info("deinit")

        managerQueue.sync {
            disconnect()
        }
    }

    // MARK: Internal

    var rxBuffer = Data()
    var updatesHandler: SensorConnectionHandler?

    var serviceUuid: [CBUUID]!
    var manager: CBCentralManager!
    let managerQueue = DispatchQueue(label: "libre-direct.sensor-ble-connection.queue")

    var stayConnected = false
    var sensor: Sensor?

    var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self

            UserDefaults.standard.peripheralUuid = peripheral?.identifier.uuidString
        }
    }

    func pairSensor(updatesHandler: @escaping SensorConnectionHandler) {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("PairSensor")

        self.updatesHandler = updatesHandler

        UserDefaults.standard.peripheralUuid = nil

        sendUpdate(connectionState: .pairing)

        managerQueue.async {
            self.find()
        }
    }

    func connectSensor(sensor: Sensor, updatesHandler: @escaping SensorConnectionHandler) {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("ConnectSensor: \(sensor)")

        self.sensor = sensor
        self.updatesHandler = updatesHandler

        managerQueue.async {
            self.find()
        }
    }

    func disconnectSensor() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("DisconnectSensor")

        managerQueue.sync {
            self.disconnect()
        }
    }

    func find() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("find")

        setStayConnected(stayConnected: true)

        guard manager.state == .poweredOn else {
            Log.error("Bad bluetooth state, manager.state \(manager.state.rawValue)")
            return
        }

        if let peripheralUuidString = UserDefaults.standard.peripheralUuid,
           let peripheralUuid = UUID(uuidString: peripheralUuidString),
           let retrievedPeripheral = manager.retrievePeripherals(withIdentifiers: [peripheralUuid]).first
        {
            connect(retrievedPeripheral)
        } else {
            scan()
        }
    }

    func scan() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("scan")

        sendUpdate(connectionState: .scanning)
        manager.scanForPeripherals(withServices: serviceUuid, options: nil)
    }

    func disconnect() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Disconnect")

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
        updatesHandler = nil
    }

    func connect() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Connect")

        if let peripheral = peripheral {
            connect(peripheral)
        } else {
            find()
        }
    }

    func connect(_ peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Connect: \(peripheral)")

        if self.peripheral != peripheral {
            self.peripheral = peripheral
        }

        manager.connect(peripheral, options: nil)
        sendUpdate(connectionState: .connecting)
    }

    func resetBuffer() {
        Log.info("ResetBuffer")
        rxBuffer = Data()
    }

    func setStayConnected(stayConnected: Bool) {
        Log.info("StayConnected: \(stayConnected.description)")
        self.stayConnected = stayConnected
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        Log.info("State: \(manager.state.rawValue)")

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
        Log.info("Peripheral: \(peripheral), didFailToConnect")

        sendUpdate(connectionState: .disconnected)

        if let error = error, let errorCode = CBError.Code(rawValue: (error as NSError).code) {
            sendUpdate(errorCode: errorCode.rawValue)
        } else {
            sendUpdate(error: error)
        }

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral), didDisconnectPeripheral")

        sendUpdate(connectionState: .disconnected)
        
        if let error = error, let errorCode = CBError.Code(rawValue: (error as NSError).code) {
            sendUpdate(errorCode: errorCode.rawValue) // code 7 - bad unlock count
        } else {
            sendUpdate(error: error)
        }

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(connectionState: .connected)
        peripheral.discoverServices(serviceUuid)
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
