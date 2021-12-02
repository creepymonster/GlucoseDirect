//
//  DeviceService.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - sensorMiddelware

func sensorMiddelware(service: SensorServiceProtocol) -> Middleware<AppState, AppAction> {
    return sensorMiddelware(sensorService: service, calibrationService: CalibrationService())
}

private func sensorMiddelware(sensorService: SensorServiceProtocol, calibrationService: CalibrationService) -> Middleware<AppState, AppAction> {
    return { store, action, _ in
        let updatesHandler: SensorUpdatesHandler = { update -> Void in
            let dispatch = store.dispatch
            var action: AppAction?

            if let connectionUpdate = update as? SensorConnectionStateUpdate {
                action = .setConnectionState(connectionState: connectionUpdate.connectionState)

            } else if let readingUpdate = update as? SensorReadingUpdate {
                if let nextReading = readingUpdate.nextReading {
                    action = .addSensorReadings(nextReading: nextReading, trendReadings: readingUpdate.trendReadings, historyReadings: readingUpdate.historyReadings)
                } else {
                    action = .addMissedReading
                }

            } else if let stateUpdate = update as? SensorStateUpdate {
                action = .setSensorState(sensorAge: stateUpdate.sensorAge, sensorState: stateUpdate.sensorState)

            } else if let errorUpdate = update as? SensorErrorUpdate {
                action = .setConnectionError(errorMessage: errorUpdate.errorMessage, errorTimestamp: errorUpdate.errorTimestamp)

            } else if let sensorUpdate = update as? SensorUpdate {
                action = .setSensor(sensor: sensorUpdate.sensor)
            } else if let transmitterUpdate = update as? SensorTransmitterUpdate {
                action = .setTransmitter(transmitter: transmitterUpdate.transmitter)
                
            }

            if let action = action {
                DispatchQueue.main.async {
                    dispatch(action)
                }
            }
        }

        switch action {
        case .addSensorReadings(nextReading: let nextReading, trendReadings: let trendReadings, historyReadings: _):
            if let sensor = store.state.sensor, let glucose = calibrationService.calibrate(sensor: sensor, nextReading: nextReading, currentGlucose: store.state.currentGlucose) {
                guard store.state.currentGlucose == nil || store.state.currentGlucose!.timestamp < nextReading.timestamp else {
                    break
                }

                if store.state.glucoseValues.isEmpty {
                    let calibratedTrend = trendReadings.map { reading in
                        calibrationService.calibrate(sensor: sensor, nextReading: reading)
                    }.compactMap { $0 }

                    if trendReadings.isEmpty {
                        store.dispatch(.addGlucose(glucose: glucose))
                    } else {
                        store.dispatch(.addGlucoseValues(glucoseValues: calibratedTrend))
                    }
                } else {
                    store.dispatch(.addGlucose(glucose: glucose))
                }
            }

        case .pairSensor:
            sensorService.pairSensor(updatesHandler: updatesHandler)

        case .connectSensor:
            guard let sensor = store.state.sensor else {
                break
            }

            sensorService.connectSensor(sensor: sensor, updatesHandler: updatesHandler)
        case .disconnectSensor:
            sensorService.disconnectSensor()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - DeviceUpdatesHandler

typealias SensorUpdatesHandler = (_ update: SensorServiceUpdate) -> Void

// MARK: - DeviceService

typealias SensorService = SensorServiceClass & SensorServiceProtocol

// MARK: - SensorServiceProtocol

protocol SensorServiceProtocol {
    func pairSensor(updatesHandler: @escaping SensorUpdatesHandler)
    func connectSensor(sensor: Sensor, updatesHandler: @escaping SensorUpdatesHandler)
    func disconnectSensor()
}

// MARK: - SensorServiceClass

class SensorServiceClass: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: Lifecycle

    init(serviceUuid: [CBUUID]) {
        super.init()

        self.serviceUuid = serviceUuid
        self.manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true, CBCentralManagerOptionRestoreIdentifierKey: "libre-direct.ble-device.restore-identifier"])
    }

    deinit {
        disconnect()
    }

    // MARK: Internal

    var rxBuffer = Data()
    var updatesHandler: SensorUpdatesHandler?

    var manager: CBCentralManager!
    let managerQueue = DispatchQueue(label: "libre-direct.ble-device.queue") // , qos: .unspecified
    var serviceUuid: [CBUUID] = []

    var stayConnected = false
    var sensor: Sensor?

    var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self

            UserDefaults.standard.devicePeripheralUuid = peripheral?.identifier.uuidString
        }
    }
    
    func connectSensor(sensor: Sensor, updatesHandler: @escaping SensorUpdatesHandler) {
        dispatchPrecondition(condition: .notOnQueue(managerQueue))
        Log.info("ConnectSensor: \(sensor)")

        self.updatesHandler = updatesHandler
        self.sensor = sensor

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

        if let peripheralUuidString = UserDefaults.standard.devicePeripheralUuid,
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

    // MARK: - sendUpdate

    func sendUpdate(connectionState: SensorConnectionState) {
        Log.info("ConnectionState: \(connectionState.description)")
        updatesHandler?(SensorConnectionStateUpdate(connectionState: connectionState))
    }

    func sendUpdate(sensor: Sensor) {
        Log.info("Sensor: \(sensor.description)")
        updatesHandler?(SensorUpdate(sensor: sensor))
    }
    
    func sendUpdate(transmitter: Transmitter) {
        Log.info("Transmitter: \(transmitter.description)")
        updatesHandler?(SensorTransmitterUpdate(transmitter: transmitter))
    }

    func sendUpdate(age: Int, state: SensorState) {
        Log.info("SensorAge: \(age.description)")
        updatesHandler?(SensorStateUpdate(sensorAge: age, sensorState: state))
    }

    func sendUpdate(trendReadings: [SensorReading] = [], historyReadings: [SensorReading] = []) {
        Log.info("SensorTrendReadings: \(trendReadings)")
        Log.info("SensorHistoryReadings: \(historyReadings)")

        updatesHandler?(SensorReadingUpdate(nextReading: trendReadings.last, trendReadings: trendReadings, historyReadings: historyReadings))
    }

    func sendUpdate(error: Error?) {
        guard let error = error else {
            return
        }

        sendUpdate(errorMessage: error.localizedDescription)
    }

    func sendUpdate(errorMessage: String) {
        Log.error("ErrorMessage: \(errorMessage)")
        updatesHandler?(SensorErrorUpdate(errorMessage: errorMessage))
    }

    func sendUpdate(errorCode: Int) {
        Log.error("ErrorCode: \(errorCode)")
        updatesHandler?(SensorErrorUpdate(errorCode: errorCode))
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

private extension UserDefaults {
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

private func crc16(_ data: Data) -> UInt16 {
    let crc16table: [UInt16] = [0, 4489, 8978, 12955, 17956, 22445, 25910, 29887, 35912, 40385, 44890, 48851, 51820, 56293, 59774, 63735, 4225, 264, 13203, 8730, 22181, 18220, 30135, 25662, 40137, 36160, 49115, 44626, 56045, 52068, 63999, 59510, 8450, 12427, 528, 5017, 26406, 30383, 17460, 21949, 44362, 48323, 36440, 40913, 60270, 64231, 51324, 55797, 12675, 8202, 4753, 792, 30631, 26158, 21685, 17724, 48587, 44098, 40665, 36688, 64495, 60006, 55549, 51572, 16900, 21389, 24854, 28831, 1056, 5545, 10034, 14011, 52812, 57285, 60766, 64727, 34920, 39393, 43898, 47859, 21125, 17164, 29079, 24606, 5281, 1320, 14259, 9786, 57037, 53060, 64991, 60502, 39145, 35168, 48123, 43634, 25350, 29327, 16404, 20893, 9506, 13483, 1584, 6073, 61262, 65223, 52316, 56789, 43370, 47331, 35448, 39921, 29575, 25102, 20629, 16668, 13731, 9258, 5809, 1848, 65487, 60998, 56541, 52564, 47595, 43106, 39673, 35696, 33800, 38273, 42778, 46739, 49708, 54181, 57662, 61623, 2112, 6601, 11090, 15067, 20068, 24557, 28022, 31999, 38025, 34048, 47003, 42514, 53933, 49956, 61887, 57398, 6337, 2376, 15315, 10842, 24293, 20332, 32247, 27774, 42250, 46211, 34328, 38801, 58158, 62119, 49212, 53685, 10562, 14539, 2640, 7129, 28518, 32495, 19572, 24061, 46475, 41986, 38553, 34576, 62383, 57894, 53437, 49460, 14787, 10314, 6865, 2904, 32743, 28270, 23797, 19836, 50700, 55173, 58654, 62615, 32808, 37281, 41786, 45747, 19012, 23501, 26966, 30943, 3168, 7657, 12146, 16123, 54925, 50948, 62879, 58390, 37033, 33056, 46011, 41522, 23237, 19276, 31191, 26718, 7393, 3432, 16371, 11898, 59150, 63111, 50204, 54677, 41258, 45219, 33336, 37809, 27462, 31439, 18516, 23005, 11618, 15595, 3696, 8185, 63375, 58886, 54429, 50452, 45483, 40994, 37561, 33584, 31687, 27214, 22741, 18780, 15843, 11370, 7921, 3960]
    var crc = data.reduce(UInt16(0xFFFF)) { ($0 >> 8) ^ crc16table[Int(($0 ^ UInt16($1)) & 0xFF)] }
    var reverseCrc = UInt16(0)
    for _ in 0 ..< 16 {
        reverseCrc = reverseCrc << 1 | crc & 1
        crc >>= 1
    }
    return reverseCrc
}

// https://github.com/dabear/LibreTransmitter/blob/main/LibreSensor/SensorContents/SensorData.swift
private func readBits(_ buffer: Data, _ byteOffset: Int, _ bitOffset: Int, _ bitCount: Int) -> Int {
    guard bitCount != 0 else {
        return 0
    }
    var res = 0
    for i in 0 ..< bitCount {
        let totalBitOffset = byteOffset * 8 + bitOffset + i
        let byte = Int(floor(Float(totalBitOffset) / 8))
        let bit = totalBitOffset % 8
        if totalBitOffset >= 0, ((buffer[byte] >> bit) & 0x1) == 1 {
            res |= 1 << i
        }
    }
    return res
}

private func writeBits(_ buffer: Data, _ byteOffset: Int, _ bitOffset: Int, _ bitCount: Int, _ value: Int) -> Data {
    var res = buffer
    for i in 0 ..< bitCount {
        let totalBitOffset = byteOffset * 8 + bitOffset + i
        let byte = Int(floor(Double(totalBitOffset) / 8))
        let bit = totalBitOffset % 8
        let bitValue = (value >> i) & 0x1
        res[byte] = (res[byte] & ~(1 << bit) | (UInt8(bitValue) << bit))
    }
    return res
}
