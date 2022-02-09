//
//  BellmanNotification.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

func bellmanAlarmMiddelware() -> Middleware<AppState, AppAction> {
    let subject = PassthroughSubject<AppAction, AppError>()

    return bellmanAlarmMiddelware(service: LazyService<BellmanAlarmService>(initialization: {
        BellmanAlarmService(subject: subject)
    }), subject: subject)
}

private func bellmanAlarmMiddelware(service: LazyService<BellmanAlarmService>, subject: PassthroughSubject<AppAction, AppError>) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            return subject.eraseToAnyPublisher()

        case .setBellmanNotification(enabled: let enabled):
            if enabled {
                service.value.connectDevice()
            } else {
                service.value.disconnectDevice()
            }

        case .bellmanTestAlarm:
            service.value.notifyDevice()

        case .addGlucoseValues(glucoseValues: let glucoseValues):
            guard state.bellmanAlarm else {
                break
            }

            guard let glucose = glucoseValues.last else {
                AppLog.info("Guard: glucoseValues.last is nil")
                break
            }

            guard glucose.type == .cgm else {
                AppLog.info("Guard: glucose.type is not .cgm")
                break
            }

            guard let glucoseValue = glucose.glucoseValue else {
                AppLog.info("Guard: glucose.glucoseValue is nil")
                break
            }

            var isSnoozed = false
            if let snoozeUntil = state.alarmSnoozeUntil, Date() < snoozeUntil {
                isSnoozed = true
            }

            guard !isSnoozed else {
                break
            }

            if glucoseValue < state.alarmLow {
                AppLog.info("Glucose alert, low: \(glucose.glucoseValue) < \(state.alarmLow)")

                service.value.notifyDevice()

            } else if glucoseValue > state.alarmHigh {
                AppLog.info("Glucose alert, high: \(glucose.glucoseValue) > \(state.alarmHigh)")

                service.value.notifyDevice()
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - BellmanConnectionState

enum BellmanConnectionState: String {
    case connected = "Connected"
    case connecting = "Connecting"
    case disconnected = "Disconnected"
    case unknown = "Unknown"

    // MARK: Lifecycle

    init() {
        self = .unknown
    }

    // MARK: Internal

    var description: String {
        rawValue
    }

    var localizedString: String {
        LocalizedString(rawValue)
    }
}

// MARK: - BellmanAlarmService

private class BellmanAlarmService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<AppAction, AppError>) {
        AppLog.info("Create BellmanAlarmService")
        super.init()

        self.subject = subject
        manager = CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    // MARK: Internal

    private(set) var stayConnected = false
    private(set) var isConnected = false
    private(set) var shouldNotify = false

    var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self

            UserDefaults.standard.bellmanPeripheralUUID = peripheral?.identifier.uuidString
        }
    }

    func connectDevice() {
        AppLog.info("ConnectDevice")

        setStayConnected(stayConnected: true)

        managerQueue.async {
            self.connect()
        }
    }

    func disconnectDevice() {
        AppLog.info("DisconnectDevice")

        setStayConnected(stayConnected: false)

        managerQueue.sync {
            self.disconnect()
        }
    }

    func notifyDevice() {
        AppLog.info("NotifyDevice")

        guard isConnected else {
            AppLog.info("NotifyDevice, device is not connected")

            setShouldNotify(shouldNotify: true)
            connectDevice()

            return
        }

        managerQueue.sync {
            self.notify(type: .withoutResponse)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch manager.state {
        case .poweredOff:
            AppLog.info("PoweredOff")

        case .poweredOn:
            AppLog.info("PoweredOn")

            guard stayConnected else {
                break
            }

            connect()

        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        AppLog.info("DidDiscover peripheral: \(peripheral)")
        AppLog.info("AdvertisementData: \(advertisementData)")
        AppLog.info("RSSI: \(RSSI)")

        guard peripheral.name?.lowercased().starts(with: peripheralName) ?? false else {
            return
        }

        manager.stopScan()
        connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        AppLog.info("DidFailToConnect peripheral: \(peripheral)")

        if let error = error {
            AppLog.error("DidFailToConnect error: \(error.localizedDescription)")
        }

        setConnectionState(connectionState: .disconnected)

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        AppLog.info("DidDisconnectPeripheral peripheral: \(peripheral)")

        if let error = error {
            AppLog.error("DidDisconnectPeripheral error: \(error.localizedDescription)")
        }

        setConnectionState(connectionState: .disconnected)

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        AppLog.info("DidConnect peripheral: \(peripheral)")

        setConnectionState(connectionState: .connected)
        peripheral.discoverServices([commandServiceUUID, deviceServiceUUID])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        AppLog.info("DidDiscoverServices peripheral: \(peripheral)")

        if let error = error {
            AppLog.error("DidDiscoverServices error: \(error.localizedDescription)")
        }

        if let services = peripheral.services {
            for service in services {
                AppLog.info("Service Uuid: \(service.uuid.description)")
                AppLog.info("Service: \(service)")

                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        AppLog.info("DidDiscoverCharacteristicsFor peripheral: \(peripheral)")

        if let error = error {
            AppLog.error("DidDiscoverCharacteristicsFor error: \(error.localizedDescription)")
        }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                AppLog.info("Characteristic Uuid: \(characteristic.uuid.description)")
                AppLog.info("Characteristic: \(characteristic)")

                if characteristic.uuid == commandCharacteristicUUID {
                    AppLog.info("Characteristic: commandCharacteristicUuid")
                    commandCharacteristic = characteristic

                    peripheral.setNotifyValue(true, for: characteristic)
                }

                if characteristic.uuid == writeCharacteristicUUID {
                    AppLog.info("Characteristic: writeCharacteristicUuid")
                    writeCharacteristic = characteristic

                    if shouldNotify {
                        managerQueue.asyncAfter(deadline: .now() + .milliseconds(250)) {
                            self.notify(type: .withoutResponse)
                        }
                    }
                }

                if characteristic.uuid == firmwareCharacteristicUUID {
                    AppLog.info("Characteristic: firmwareCharacteristicUuid")
                    firmwareCharacteristic = characteristic

                    peripheral.writeValue(Data([]), for: characteristic, type: .withResponse)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        AppLog.info("DidUpdateNotificationStateFor peripheral: \(peripheral)")

        if let error = error {
            AppLog.error("DidUpdateNotificationStateFor error: \(error.localizedDescription)")
        }

        guard let data = characteristic.value else {
            return
        }

        AppLog.info("DidUpdateNotificationStateFor characteristic: \(characteristic.uuid.description)")
        AppLog.info("DidUpdateNotificationStateFor data: \(data.hex)")
        AppLog.info("DidUpdateNotificationStateFor data.count: \(data.count)")

        if characteristic.uuid == commandCharacteristicUUID {
            analysis([UInt8](data))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        AppLog.info("DidWriteValueFor peripheral: \(peripheral)")

        if let error = error {
            AppLog.error("DidWriteValueFor error: \(error.localizedDescription)")
        }

        guard let data = characteristic.value else {
            return
        }

        AppLog.info("DidWriteValueFor characteristic: \(characteristic.uuid.description)")
        AppLog.info("DidWriteValueFor data: \(data.hex)")
        AppLog.info("DidWriteValueFor data.count: \(data.count)")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        AppLog.info("DidUpdateValueFor peripheral: \(peripheral)")

        if let error = error {
            AppLog.error("DidUpdateValueFor error: \(error.localizedDescription)")
        }

        guard let data = characteristic.value else {
            return
        }

        AppLog.info("DidUpdateValueFor characteristic: \(characteristic.uuid.description)")
        AppLog.info("DidUpdateValueFor data: \(data.hex)")
        AppLog.info("DidUpdateValueFor data.count: \(data.count)")
    }

    func connect() {
        AppLog.info("Connect")

        setConnectionState(connectionState: .connecting)

        if let peripheral = peripheral {
            connect(peripheral)
        } else {
            find()
        }
    }

    // MARK: Private

    private weak var subject: PassthroughSubject<AppAction, AppError>?

    private var manager: CBCentralManager!
    private let managerQueue = DispatchQueue(label: "libre-direct.bellman-connection.queue")

    private var commandServiceUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    private var deviceServiceUUID = CBUUID(string: "0000180a-0000-1000-8000-00805f9b34fb")

    private let firmwareCharacteristicUUID = CBUUID(string: "00002a26-0000-1000-8000-00805f9b34fb")
    private var firmwareCharacteristic: CBCharacteristic?

    private let writeCharacteristicUUID = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    private var writeCharacteristic: CBCharacteristic?

    private let commandCharacteristicUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    private var commandCharacteristic: CBCharacteristic?

    private var peripheralName: String {
        "phone transceiver"
    }

    private func analysis(_ bArr: [UInt8]) {
        let sender = bytesToHex(subBytes(bArr, 4, 3))
        AppLog.info("Sender: \(sender)")

        let receiver = bytesToHex(subBytes(bArr, 7, 3))
        AppLog.info("Receiver: \(receiver)")
    }

    private func conver2HexStr(_ bArr: [UInt8]) -> String {
        var hex = ""

        for s in bArr {
            hex += String(s & 255, radix: 2)
        }

        return hex
    }

    private func bytes2BigEnd(_ bArr: [UInt8]) -> [UInt8] {
        return bArr.reversed()
    }

    private func bytesToHex(_ bArr: [UInt8]) -> String {
        var hex = ""

        for b in bArr {
            let hexPart = String(format: "%02X", b & 255)
            if hexPart.count < 2 {
                hex += "0"
            }

            hex += hexPart
        }

        return hex
    }

    private func subBytes(_ bArr: [UInt8], _ i: Int, _ i2: Int) -> [UInt8] {
        var bArr2 = [UInt8](repeating: 0, count: i2)

        for i3 in i ..< i + i2 {
            bArr2[i3 - i] = bArr[i3]
        }

        return bArr2
    }

    private func find() {
        AppLog.info("Find")

        guard manager.state == .poweredOn else {
            AppLog.error("Guard: manager.state \(manager.state.rawValue) is not .poweredOn")
            return
        }

        if let connectedPeripheral = manager.retrieveConnectedPeripherals(withServices: [commandServiceUUID]).first(where: {
            guard let name = $0.name?.lowercased() else {
                return false
            }

            AppLog.info("Found peripheral, name: '\(name)' and searching for: '\(peripheralName)'")

            return name == peripheralName
        }) {
            AppLog.info("Connect from retrievePeripherals: \(connectedPeripheral)")

            connect(connectedPeripheral)
        } else if stayConnected {
            managerQueue.asyncAfter(deadline: .now() + .seconds(5)) {
                self.find()
            }
        }
    }

    private func connect(_ peripheral: CBPeripheral) {
        AppLog.info("Connect: \(peripheral)")

        self.peripheral = peripheral
        manager.connect(peripheral, options: nil)
    }

    private func disconnect() {
        AppLog.info("Disconnect")

        if manager.isScanning {
            manager.stopScan()
        }

        if let peripheral = peripheral {
            manager.cancelPeripheralConnection(peripheral)
            self.peripheral = nil
        }

        setConnectionState(connectionState: .disconnected)
    }

    private func notify(type: CBCharacteristicWriteType) {
        AppLog.info("Notify")

        setShouldNotify(shouldNotify: false)

        if let peripheral = peripheral, let writeCharacteristic = writeCharacteristic {
            // without sender
            peripheral.writeValue(Data([218, 6, 0, 36, 0, 0, 0, 0, 0, 128, 0, 2, 129, 0, 1, 1]), for: writeCharacteristic, type: type)

            // with sender
            // peripheral.writeValue(Data([112, 6, 0, 36, 175, 9, 0, 0, 0, 128, 0, 2, 129, 0, 1, 1]), for: writeCharacteristic, type: type)
        }
    }

    private func setConnectionState(connectionState: BellmanConnectionState) {
        subject?.send(.setBellmanConnectionState(connectionState: connectionState))
        isConnected = connectionState == .connected
    }

    private func setShouldNotify(shouldNotify: Bool) {
        AppLog.info("ShouldNotify: \(shouldNotify.description)")

        self.shouldNotify = shouldNotify
    }

    private func setStayConnected(stayConnected: Bool) {
        AppLog.info("StayConnected: \(stayConnected.description)")

        self.stayConnected = stayConnected
    }
}

private extension UserDefaults {
    private enum Keys: String {
        case bellmanPeripheralUUID = "libre-direct.bellman.peripheral-uuid"
    }

    var bellmanPeripheralUUID: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.bellmanPeripheralUUID.rawValue)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.setValue(newValue, forKey: Keys.bellmanPeripheralUUID.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.bellmanPeripheralUUID.rawValue)
            }
        }
    }
}
