//
//  Libre2Connection.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - Libre2Connection

final class Libre2Connection: SensorConnection {
    // MARK: Lifecycle

    required init() {
        super.init()

        self.manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true, CBCentralManagerOptionRestoreIdentifierKey: "libre-direct.ble-device.restore-identifier"])
    }

    deinit {
        managerQueue.sync {
            disconnect()
        }
    }

    // MARK: Internal

    func pairSensor(updatesHandler: @escaping SensorConnectionHandler) {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("PairSensor")

        self.updatesHandler = updatesHandler

        Task {
            let pairingService = Libre2Pairing()
            let pairedSensor = await pairingService.pairSensor()

            UserDefaults.standard.libre2UnlockCount = 0

            if let pairedSensor = pairedSensor {
                sendUpdate(sensor: pairedSensor)

                if let fram = pairedSensor.fram, pairedSensor.state == .ready {
                    let parsedFram = Libre2.parseFRAM(calibration: pairedSensor.factoryCalibration, pairingTimestamp: pairedSensor.pairingTimestamp, fram: fram)

                    sendUpdate(trendReadings: parsedFram.trend, historyReadings: parsedFram.history)
                }
            }
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

    func unlock() -> Data? {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Unlock")

        if sensor == nil {
            return nil
        }

        UserDefaults.standard.libre2UnlockCount = UserDefaults.standard.libre2UnlockCount + 1

        let unlockPayload = Libre2.streamingUnlockPayload(uuid: sensor!.uuid, patchInfo: sensor!.patchInfo, enableTime: 42, unlockCount: UInt16(UserDefaults.standard.libre2UnlockCount))
        return Data(unlockPayload)
    }

    func find() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("find")

        setStayConnected(stayConnected: true)

        guard manager.state == .poweredOn else {
            return
        }

        if let peripheralUuidString = UserDefaults.standard.libre2PeripheralUuid,
           let peripheralUuid = UUID(uuidString: peripheralUuidString),
           let retrievedPeripheral = manager.retrievePeripherals(withIdentifiers: [peripheralUuid]).first
        {
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

    // MARK: Private

    private let expectedBufferSize = 46
    private var rxBuffer = Data()

    private var manager: CBCentralManager!
    private let managerQueue = DispatchQueue(label: "libre-direct.ble-device.queue")

    private var serviceUuid: [CBUUID] = [CBUUID(string: "FDE3")]
    private var writeCharacteristicUuid = CBUUID(string: "F001")
    private var readCharacteristicUuid = CBUUID(string: "F002")

    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?

    private var stayConnected = false
    private var sensor: Sensor?

    private var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self

            UserDefaults.standard.libre2PeripheralUuid = peripheral?.identifier.uuidString
        }
    }
}

// MARK: CBCentralManagerDelegate

extension Libre2Connection: CBCentralManagerDelegate {
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

    // MARK: - CBCentralManagerDelegate

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        guard let sensor = sensor, let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }

        Log.info("Sensor: \(sensor)")
        Log.info("ManufacturerData: \(manufacturerData)")

        if manufacturerData.count == 8 {
            var foundUUID = manufacturerData.subdata(in: 2 ..< 8)
            foundUUID.append(contentsOf: [0x07, 0xe0])

            let result = foundUUID == sensor.uuid && peripheral.name?.lowercased().starts(with: "abbott") ?? false
            if result {
                manager.stopScan()                
                connect(peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(connectionState: .connected)

        peripheral.discoverServices(serviceUuid)
    }
}

// MARK: CBPeripheralDelegate

extension Libre2Connection: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                Log.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics([readCharacteristicUuid, writeCharacteristicUuid], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                Log.info("Characteristic Uuid: \(characteristic.uuid.description)")

                if characteristic.uuid == readCharacteristicUuid {
                    readCharacteristic = characteristic
                }

                if characteristic.uuid == writeCharacteristicUuid {
                    writeCharacteristic = characteristic

                    if let unlock = unlock() {
                        peripheral.writeValue(unlock, for: characteristic, type: .withResponse)
                    }
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if characteristic.uuid == writeCharacteristicUuid {
            peripheral.setNotifyValue(true, for: readCharacteristic!)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        guard let value = characteristic.value else {
            return
        }

        rxBuffer.append(value)

        if rxBuffer.count == expectedBufferSize {
            if let sensor = sensor {
                do {
                    let decryptedBLE = Data(try Libre2.decryptBLE(uuid: sensor.uuid, data: rxBuffer))
                    let parsedBLE = Libre2.parseBLE(calibration: sensor.factoryCalibration, data: decryptedBLE)

                    if parsedBLE.age >= sensor.lifetime {
                        sendUpdate(age: parsedBLE.age, state: .expired)
                    } else if parsedBLE.age > sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .ready)
                        sendUpdate(trendReadings: parsedBLE.trend, historyReadings: parsedBLE.history)
                    } else if parsedBLE.age <= sensor.warmupTime {
                        sendUpdate(age: parsedBLE.age, state: .starting)
                    }

                    resetBuffer()
                } catch {
                    resetBuffer()
                }
            }
        }
    }
}

// MARK: - fileprivate

private extension UserDefaults {
    enum Keys: String {
        case devicePeripheralUuid = "libre-direct.libre2.peripheral-uuid"
        case libre2UnlockCount = "libre-direct.libre2.unlock-count"
    }

    var libre2PeripheralUuid: String? {
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

    var libre2UnlockCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.libre2UnlockCount.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.libre2UnlockCount.rawValue)
        }
    }
}
