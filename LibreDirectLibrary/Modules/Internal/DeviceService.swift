//
//  DeviceService.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 01.10.21.
//

import Foundation
import CoreBluetooth
import Combine

// MARK: - deviceMiddelware
func deviceMiddelware(service: DeviceServiceProtocol) -> Middleware<AppState, AppAction> {
    return { store, action, lastState in
        switch action {
        case .pairSensor:
            Task {
                let dispatch = store.dispatch

                let sensor = await service.pairSensor()
                if let sensor = sensor {
                    DispatchQueue.main.async {
                        dispatch(.setSensor(value: sensor))
                    }
                }
            }

        case .connectSensor:
            guard let sensor = store.state.sensor else {
                break
            }

            service.connectSensor(sensor: sensor) { (update) -> Void in
                let dispatch = store.dispatch
                var action: AppAction? = nil

                if let connectionUpdate = update as? DeviceServiceConnectionUpdate {
                    action = .setSensorConnection(connectionState: connectionUpdate.connectionState)

                } else if let readingUpdate = update as? DeviceServiceGlucoseUpdate {
                    if let glucose = readingUpdate.glucose {
                        action = .setSensorReading(glucose: glucose)
                    } else {
                        action = .setSensorMissedReadings
                    }

                } else if let ageUpdate = update as? DeviceServiceAgeUpdate {
                    action = .setSensorAge(sensorAge: ageUpdate.sensorAge)

                } else if let errorUpdate = update as? DeviceServiceErrorUpdate {
                    action = .setSensorError(errorMessage: errorUpdate.errorMessage, errorTimestamp: errorUpdate.errorTimestamp)

                } else if let sensorUpdate = update as? DeviceServiceSensorUpdate {
                    action = .setSensor(value: sensorUpdate.sensor)

                } else if let infoUpdate = update as? DeviceServiceInfoUpdate {
                    action = .setDeviceInfo(value: infoUpdate.info)

                }

                if let action = action {
                    DispatchQueue.main.async {
                        dispatch(action)
                    }
                }
            }

        case .disconnectSensor:
            service.disconnectSensor()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - DeviceUpdatesHandler
typealias DeviceUpdatesHandler = (_ update: DeviceServiceUpdate) -> Void

// MARK: - DeviceService
typealias DeviceService = DeviceServiceClass & DeviceServiceProtocol

// MARK: - DeviceServiceProtocol
protocol DeviceServiceProtocol {
    func pairSensor() async -> Sensor?
    func connectSensor(sensor: Sensor, updatesHandler: @escaping DeviceUpdatesHandler)
    func disconnectSensor()
}

// MARK: - DeviceServiceClass
class DeviceServiceClass: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var rxBuffer = Data()
    var updatesHandler: DeviceUpdatesHandler?

    var manager: CBCentralManager! = nil
    let managerQueue: DispatchQueue = DispatchQueue(label: "libre-direct.ble-device.queue") // , qos: .unspecified
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
        self.manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true, CBCentralManagerOptionRestoreIdentifierKey: "libre-direct.ble-device.restore-identifier"])
    }

    deinit {
        disconnect()
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
        } else if let retrievedPeripheral = manager.retrieveConnectedPeripherals(withServices: serviceUuid).first {
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

    // MARK: - sendUpdate
    func sendUpdate(connectionState: SensorConnectionState) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        Log.info("ConnectionState: \(connectionState.description)")
        self.updatesHandler?(DeviceServiceConnectionUpdate(connectionState: connectionState))
    }

    func sendUpdate(sensor: Sensor) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        Log.info("Sensor: \(sensor.description)")
        self.updatesHandler?(DeviceServiceSensorUpdate(sensor: sensor))
    }

    func sendUpdate(sensorAge: Int) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        Log.info("SensorAge: \(sensorAge.description)")
        self.updatesHandler?(DeviceServiceAgeUpdate(sensorAge: sensorAge))
    }

    func sendEmptyGlucoseUpdate() {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        Log.info("Empty glucose update!")
        self.updatesHandler?(DeviceServiceGlucoseUpdate())
    }

    func sendUpdate(glucose: SensorGlucose) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        if let lastGlucose = lastGlucose {
            glucose.minuteChange = calculateSlope(secondLast: lastGlucose, last: glucose)
        }

        Log.info("Glucose: \(glucose.description)")

        lastGlucose = glucose
        self.updatesHandler?(DeviceServiceGlucoseUpdate(lastGlucose: glucose))
    }

    func sendUpdate(error: Error?) {
        guard let error = error else {
            return
        }

        sendUpdate(errorMessage: error.localizedDescription)
    }

    func sendUpdate(errorMessage: String) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        Log.error("ErrorMessage: \(errorMessage)")
        self.updatesHandler?(DeviceServiceErrorUpdate(errorMessage: errorMessage))
    }

    func sendUpdate(errorCode: Int) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        Log.error("ErrorCode: \(errorCode)")
        self.updatesHandler?(DeviceServiceErrorUpdate(errorCode: errorCode))
    }

    // MARK: - CBCentralManagerDelegate
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

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral), willRestoreState")
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral), didFailToConnect")

        sendUpdate(connectionState: .disconnected)
        sendUpdate(error: error)

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral), didDisconnectPeripheral")

        sendUpdate(connectionState: .disconnected)
        sendUpdate(error: error)

        guard stayConnected else {
            return
        }

        connect()
    }
}

// MARK: - fileprivate
fileprivate func calculateDiffInMinutes(secondLast: Date, last: Date) -> Double {
    let diff = last.timeIntervalSince(secondLast)
    return diff / 60
}

fileprivate func calculateSlope(secondLast: SensorGlucose, last: SensorGlucose) -> Double {
    if secondLast.timestamp == last.timestamp {
        return 0.0
    }

    let glucoseDiff = Double(last.glucoseValue) - Double(secondLast.glucoseValue)
    let minutesDiff = calculateDiffInMinutes(secondLast: secondLast.timestamp, last: last.timestamp)

    return glucoseDiff / minutesDiff
}

fileprivate extension UserDefaults {
    enum Keys: String {
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
