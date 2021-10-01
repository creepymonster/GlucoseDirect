//
//  DeviceService.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 01.10.21. 
//

import Foundation
import CoreBluetooth

extension UserDefaults {
    fileprivate enum Keys: String {
        case devicePeripheralUuid = "libre-direct.bubble.peripheral-uuid"
    }

    var devicePeripheralUuid: String? {
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

class DeviceUpdate {
}

class DeviceAgeUpdate: DeviceUpdate {
    private(set) var sensorAge: Int

    init(sensorAge: Int) {
        self.sensorAge = sensorAge
    }
}

class DeviceConnectionUpdate: DeviceUpdate {
    private(set) var connectionState: SensorConnectionState

    init(connectionState: SensorConnectionState) {
        self.connectionState = connectionState
    }
}

class DeviceSensorUpdate: DeviceUpdate {
    private(set) var sensor: Sensor

    init(sensor: Sensor) {
        self.sensor = sensor
    }
}

class DeviceGlucoseUpdate: DeviceUpdate {
    private(set) var glucose: SensorGlucose?

    init(lastGlucose: SensorGlucose? = nil) {
        self.glucose = lastGlucose
    }
}

class DeviceErrorUpdate: DeviceUpdate {
    private(set) var errorMessage: String
    private(set) var errorTimestamp: Date = Date()

    init(errorMessage: String) {
        self.errorMessage = errorMessage
    }

    init(errorCode: Int) {
        self.errorMessage = translateError(errorCode: errorCode)
    }
}

typealias DeviceConnectionHandler = (_ update: DeviceUpdate) -> Void

class DeviceService : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var rxBuffer = Data()
    var connectionCompletionHandler: DeviceConnectionHandler?
    
    var manager: CBCentralManager! = nil
    let managerQueue: DispatchQueue = DispatchQueue(label: "libre-direct.ble-queue") // , qos: .unspecified
    var serviceUuid: [CBUUID] = []
    
    var stayConnected = false
    var sensor: Sensor? = nil
    var lastGlucose: SensorGlucose? = nil
    
    var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self

            UserDefaults.standard.devicePeripheralUuid = peripheral?.identifier.uuidString
        }
    }
    
    init(serviceUuid: [CBUUID]) {
        super.init()

        self.serviceUuid = serviceUuid
        self.manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    deinit {
        disconnect()
    }
    
    func connectSensor(sensor: Sensor, completionHandler: @escaping DeviceConnectionHandler) {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("ConnectSensor: \(sensor)")

        self.connectionCompletionHandler = completionHandler
        self.sensor = sensor

        managerQueue.async {
            self.find()
        }
    }

    func disconnectSensor() {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("DisconnectSensor")

        self.sensor = nil
        self.lastGlucose = nil

        managerQueue.sync {
            self.disconnect()
        }
    }
    
    func find() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("find")

        setStayConnected(stayConnected: true)

        guard manager.state == .poweredOn else {
            return
        }

        if let peripheralUuidString = UserDefaults.standard.devicePeripheralUuid,
            let peripheralUuid = UUID(uuidString: peripheralUuidString),
            let retrievedPeripheral = manager.retrievePeripherals(withIdentifiers: [peripheralUuid]).first {
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
    }

    func connect() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Connect")
        
        if let peripheral = self.peripheral {
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
    
    func sendUpdate(connectionState: SensorConnectionState) {
        Log.info("ConnectionState: \(connectionState.description)")
        self.connectionCompletionHandler?(DeviceConnectionUpdate(connectionState: connectionState))
    }
    
    func sendUpdate(sensor: Sensor) {
        Log.info("Sensor: \(sensor.description)")
        self.connectionCompletionHandler?(DeviceSensorUpdate(sensor: sensor))
    }

    func sendUpdate(sensorAge: Int) {
        Log.info("SensorAge: \(sensorAge.description)")
        self.connectionCompletionHandler?(DeviceAgeUpdate(sensorAge: sensorAge))
    }

    func sendEmptyGlucoseUpdate() {
        Log.info("Empty glucose update!")
        self.connectionCompletionHandler?(DeviceGlucoseUpdate())
    }

    func sendUpdate(glucose: SensorGlucose) {
        Log.info("Glucose: \(glucose.description)")
        self.connectionCompletionHandler?(DeviceGlucoseUpdate(lastGlucose: glucose))
    }

    func sendUpdate(error: Error?) {
        guard let error = error else {
            return
        }

        Log.error("Error: \(error.localizedDescription)")
        sendUpdate(errorMessage: error.localizedDescription)
    }

    func sendUpdate(errorMessage: String) {
        Log.error("ErrorMessage: \(errorMessage)")
        self.connectionCompletionHandler?(DeviceErrorUpdate(errorMessage: errorMessage))
    }

    func sendUpdate(errorCode: Int) {
        Log.error("ErrorCode: \(errorCode)")
        self.connectionCompletionHandler?(DeviceErrorUpdate(errorCode: errorCode))
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
}

fileprivate func translateError(errorCode: Int) -> String {
    switch errorCode {
    case 0: //case unknown = 0
        return "unknown"

    case 1: //case invalidParameters = 1
        return "invalidParameters"

    case 2: //case invalidHandle = 2
        return "invalidHandle"

    case 3: //case notConnected = 3
        return "notConnected"

    case 4: //case outOfSpace = 4
        return "outOfSpace"

    case 5: //case operationCancelled = 5
        return "operationCancelled"

    case 6: //case connectionTimeout = 6
        return "connectionTimeout"

    case 7: //case peripheralDisconnected = 7
        return "peripheralDisconnected"

    case 8: //case uuidNotAllowed = 8
        return "uuidNotAllowed"

    case 9: //case alreadyAdvertising = 9
        return "alreadyAdvertising"

    case 10: //case connectionFailed = 10
        return "connectionFailed"

    case 11: //case connectionLimitReached = 11
        return "connectionLimitReached"

    case 13: //case operationNotSupported = 13
        return "operationNotSupported"

    default:
        return ""
    }
}
