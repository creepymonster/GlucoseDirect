import Combine
import CoreBluetooth
import Foundation

// MARK: - BubbleConnection

class BubbleConnection: SensorConnection {
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
            return
        }

        if let peripheralUuidString = UserDefaults.standard.bubblePeripheralUuid,
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

    private let expectedBufferSize = 344
    private var rxBuffer = Data()

    private var manager: CBCentralManager!
    private let managerQueue = DispatchQueue(label: "libre-direct.ble-device.queue")

    private var serviceUuid: [CBUUID] = [CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")]
    private var writeCharacteristicUuid = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private var readCharacteristicUuid = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?

    private var stayConnected = false
    private var sensor: Sensor?

    private var uuid: Data?
    private var patchInfo: Data?
    private var hardware: Double?
    private var firmware: Double?

    private var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self

            UserDefaults.standard.bubblePeripheralUuid = peripheral?.identifier.uuidString
        }
    }
}

// MARK: CBCentralManagerDelegate

extension BubbleConnection: CBCentralManagerDelegate {
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

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        guard peripheral.name?.lowercased().starts(with: "bubble") ?? false else {
            return
        }

        manager.stopScan()
        connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(connectionState: .connected)
        peripheral.discoverServices(serviceUuid)
    }
}

// MARK: CBPeripheralDelegate

extension BubbleConnection: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        if let services = peripheral.services {
            for service in services {
                Log.info("Service Uuid: \(service.uuid)")

                peripheral.discoverCharacteristics([writeCharacteristicUuid, readCharacteristicUuid], for: service)
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
                    peripheral.setNotifyValue(true, for: characteristic)
                }

                if characteristic.uuid == writeCharacteristicUuid {
                    writeCharacteristic = characteristic
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        sendUpdate(error: error)

        guard let writeCharacteristic = writeCharacteristic else {
            return
        }

        peripheral.writeValue(Data([0x00, 0x00, 0x01]), for: writeCharacteristic, type: .withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        Log.info("Peripheral: \(peripheral)")

        guard let value = characteristic.value else {
            return
        }

        guard let firstByte = value.first, let bubbleResponseState = BubbleResponseType(rawValue: firstByte) else {
            return
        }

        Log.info("BubbleResponseState: \(bubbleResponseState)")

        switch bubbleResponseState {
        case .dataInfo:
            let hardwareMajor = value[value.count-2]
            let hardwareMinor = value[value.count-1]
            let hardware = Double("\(hardwareMajor).\(hardwareMinor)")
            let firmwareMajor = value[2]
            let firmwareMinor = value[3]
            let firmware = Double("\(firmwareMajor).\(firmwareMinor)")
            let battery = Int(value[4])

            if let firmware = firmware, firmware > 2.6 {
                let transmitter = Transmitter(name: "Bubble", battery: battery, firmware: hardware, hardware: firmware)
                sendUpdate(transmitter: transmitter)

                if let writeCharacteristic = writeCharacteristic {
                    peripheral.writeValue(Data([0x08, 0x01, 0x00, 0x00, 0x00, 0x2b]), for: writeCharacteristic, type: .withoutResponse)
                    // peripheral.writeValue(Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x2b]), for: writeCharacteristic, type: .withResponse)
                }
            }

        case .dataPacket:
            print("oh nein")
        case .decryptedDataPacket:
            rxBuffer.append(value.suffix(from: 4))

            if rxBuffer.count >= expectedBufferSize {
                Log.info("Completed DataPacket")

                guard let uuid = uuid, let patchInfo = patchInfo else {
                    resetBuffer()

                    return
                }

                let sensor = Libre2.sensor(uuid: uuid, patchInfo: patchInfo, fram: rxBuffer[..<344])
                if sensor.age >= sensor.lifetime {
                    sendUpdate(sensor: sensor)
                } else if sensor.age > sensor.warmupTime {
                    sendUpdate(sensor: sensor)

                    if let fram = sensor.fram {
                        let data = Libre2.parseFRAM(calibration: sensor.factoryCalibration, pairingTimestamp: sensor.pairingTimestamp, fram: fram)
                        sendUpdate(trendReadings: data.trend, historyReadings: data.history)
                    }
                } else if sensor.age <= sensor.warmupTime {
                    sendUpdate(sensor: sensor)
                }

                resetBuffer()
            }

        case .noSensor:
            resetBuffer()

        case .serialNumber:
            guard value.count >= 10 else {
                return
            }

            uuid = value.subdata(in: 2 ..< 10)

            resetBuffer()

        case .patchInfo:
            patchInfo = value.subdata(in: 5 ..< 11)
        }
    }
}

// MARK: - BubbleResponseType

private enum BubbleResponseType: UInt8 {
    case dataPacket = 130
    case dataInfo = 128 // = wakeUp + device info
    case noSensor = 191
    case serialNumber = 192
    case patchInfo = 193 // 0xC1
    case decryptedDataPacket = 136 // 0x88
}

private extension UserDefaults {
    enum Keys: String {
        case devicePeripheralUuid = "libre-direct.bubble.peripheral-uuid"
    }

    var bubblePeripheralUuid: String? {
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
