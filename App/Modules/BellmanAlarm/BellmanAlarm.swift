//
//  BellmanNotification.swift
//  GlucoseDirect
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
                DirectLog.info("Guard: glucoseValues.last is nil")
                break
            }

            guard glucose.type == .cgm else {
                DirectLog.info("Guard: glucose.type is not .cgm")
                break
            }

            guard let glucoseValue = glucose.glucoseValue else {
                DirectLog.info("Guard: glucose.glucoseValue is nil")
                break
            }

            var isSnoozed = false
            if let snoozeUntil = state.alarmSnoozeUntil, Date() < snoozeUntil {
                isSnoozed = true
            }

            guard !isSnoozed else {
                break
            }

            if glucoseValue < state.alarmLow || glucose.isLOW {
                DirectLog.info("Glucose alert, low: \(glucose.glucoseValue) < \(state.alarmLow)")

                service.value.notifyDevice()

            } else if glucoseValue > state.alarmHigh || glucose.isHIGH {
                DirectLog.info("Glucose alert, high: \(glucose.glucoseValue) > \(state.alarmHigh)")

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
        DirectLog.info("Create BellmanAlarmService")
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
        DirectLog.info("ConnectDevice")

        setStayConnected(stayConnected: true)

        managerQueue.async {
            self.connect()
        }
    }

    func disconnectDevice() {
        DirectLog.info("DisconnectDevice")

        setStayConnected(stayConnected: false)

        managerQueue.sync {
            self.disconnect()
        }
    }

    func notifyDevice() {
        DirectLog.info("NotifyDevice")

        guard isConnected else {
            DirectLog.info("NotifyDevice, device is not connected")

            setShouldNotify(shouldNotify: true)
            connectDevice()

            return
        }

        managerQueue.sync {
            self.notify(type: .withoutResponse)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard manager != nil else {
            DirectLog.error("Guard: manager is nil")
            return
        }

        switch manager.state {
        case .poweredOff:
            DirectLog.info("PoweredOff")

        case .poweredOn:
            DirectLog.info("PoweredOn")

            guard stayConnected else {
                break
            }

            connect()

        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        DirectLog.info("DidDiscover peripheral: \(peripheral)")
        DirectLog.info("AdvertisementData: \(advertisementData)")
        DirectLog.info("RSSI: \(RSSI)")

        guard peripheral.name?.lowercased().starts(with: peripheralName) ?? false else {
            return
        }

        manager.stopScan()
        connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DirectLog.info("DidFailToConnect peripheral: \(peripheral)")

        if let error = error {
            DirectLog.error("DidFailToConnect error: \(error.localizedDescription)")
        }

        setConnectionState(connectionState: .disconnected)

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DirectLog.info("DidDisconnectPeripheral peripheral: \(peripheral)")

        if let error = error {
            DirectLog.error("DidDisconnectPeripheral error: \(error.localizedDescription)")
        }

        setConnectionState(connectionState: .disconnected)

        guard stayConnected else {
            return
        }

        connect()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DirectLog.info("DidConnect peripheral: \(peripheral)")

        setConnectionState(connectionState: .connected)
        peripheral.discoverServices([commandServiceUUID, deviceServiceUUID])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        DirectLog.info("DidDiscoverServices peripheral: \(peripheral)")

        if let error = error {
            DirectLog.error("DidDiscoverServices error: \(error.localizedDescription)")
        }

        if let services = peripheral.services {
            for service in services {
                DirectLog.info("Service Uuid: \(service.uuid.description)")
                DirectLog.info("Service: \(service)")

                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        DirectLog.info("DidDiscoverCharacteristicsFor peripheral: \(peripheral)")

        if let error = error {
            DirectLog.error("DidDiscoverCharacteristicsFor error: \(error.localizedDescription)")
        }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                DirectLog.info("Characteristic Uuid: \(characteristic.uuid.description)")
                DirectLog.info("Characteristic: \(characteristic)")

                if characteristic.uuid == commandCharacteristicUUID {
                    DirectLog.info("Characteristic: commandCharacteristicUuid")
                    commandCharacteristic = characteristic

                    peripheral.setNotifyValue(true, for: characteristic)
                }

                if characteristic.uuid == writeCharacteristicUUID {
                    DirectLog.info("Characteristic: writeCharacteristicUuid")
                    writeCharacteristic = characteristic

                    if shouldNotify {
                        managerQueue.asyncAfter(deadline: .now() + .milliseconds(250)) {
                            self.notify(type: .withoutResponse)
                        }
                    }
                }

                if characteristic.uuid == firmwareCharacteristicUUID {
                    DirectLog.info("Characteristic: firmwareCharacteristicUuid")
                    firmwareCharacteristic = characteristic

                    peripheral.writeValue(Data([]), for: characteristic, type: .withResponse)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        DirectLog.info("DidUpdateNotificationStateFor peripheral: \(peripheral)")

        if let error = error {
            DirectLog.error("DidUpdateNotificationStateFor error: \(error.localizedDescription)")
        }

        guard let data = characteristic.value else {
            return
        }

        DirectLog.info("DidUpdateNotificationStateFor characteristic: \(characteristic.uuid.description)")
        DirectLog.info("DidUpdateNotificationStateFor data: \(data.hex)")
        DirectLog.info("DidUpdateNotificationStateFor data.count: \(data.count)")

        if characteristic.uuid == commandCharacteristicUUID {
            analysis([UInt8](data))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        DirectLog.info("DidWriteValueFor peripheral: \(peripheral)")

        if let error = error {
            DirectLog.error("DidWriteValueFor error: \(error.localizedDescription)")
        }

        guard let data = characteristic.value else {
            return
        }

        DirectLog.info("DidWriteValueFor characteristic: \(characteristic.uuid.description)")
        DirectLog.info("DidWriteValueFor data: \(data.hex)")
        DirectLog.info("DidWriteValueFor data.count: \(data.count)")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        DirectLog.info("DidUpdateValueFor peripheral: \(peripheral)")

        if let error = error {
            DirectLog.error("DidUpdateValueFor error: \(error.localizedDescription)")
        }

        guard let data = characteristic.value else {
            return
        }

        DirectLog.info("DidUpdateValueFor characteristic: \(characteristic.uuid.description)")
        DirectLog.info("DidUpdateValueFor data: \(data.hex)")
        DirectLog.info("DidUpdateValueFor data.count: \(data.count)")
    }

    func connect() {
        DirectLog.info("Connect")

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
        DirectLog.info("Sender: \(sender)")

        let receiver = bytesToHex(subBytes(bArr, 7, 3))
        DirectLog.info("Receiver: \(receiver)")
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
        DirectLog.info("Find")

        guard manager.state == .poweredOn else {
            DirectLog.error("Guard: manager.state \(manager.state.rawValue) is not .poweredOn")
            return
        }

        if let connectedPeripheral = manager.retrieveConnectedPeripherals(withServices: [commandServiceUUID]).first(where: {
            guard let name = $0.name?.lowercased() else {
                return false
            }

            DirectLog.info("Found peripheral, name: '\(name)' and searching for: '\(peripheralName)'")

            return name == peripheralName
        }) {
            DirectLog.info("Connect from retrievePeripherals: \(connectedPeripheral)")

            connect(connectedPeripheral)
        } else if stayConnected {
            managerQueue.asyncAfter(deadline: .now() + .seconds(5)) {
                self.find()
            }
        }
    }

    private func connect(_ peripheral: CBPeripheral) {
        DirectLog.info("Connect: \(peripheral)")

        self.peripheral = peripheral
        manager.connect(peripheral, options: nil)
    }

    private func disconnect() {
        DirectLog.info("Disconnect")

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
        DirectLog.info("Notify")

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
        DirectLog.info("ShouldNotify: \(shouldNotify.description)")

        self.shouldNotify = shouldNotify
    }

    private func setStayConnected(stayConnected: Bool) {
        DirectLog.info("StayConnected: \(stayConnected.description)")

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
