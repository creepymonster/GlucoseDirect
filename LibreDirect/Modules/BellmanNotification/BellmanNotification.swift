//
//  BellmanNotification.swift
//  LibreDirect
//

import Combine
import CoreBluetooth
import Foundation

func bellmanNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return bellmanNotificationMiddelware(service: {
        BellmanNotificationService()
    }())
}

private func bellmanNotificationMiddelware(service: BellmanNotificationService) -> Middleware<AppState, AppAction> {
    return { _, action, _ in
        switch action {
        case .setBellmanNotification(enabled: let enabled):
            if enabled {
                service.connectDevice()
            } else {
                service.disconnectDevice()
            }

        case .bellmanNotification:
            service.notifyDevice()

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - BellmanNotificationService

private class BellmanNotificationService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: Lifecycle

    override init() {
        super.init()

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

            UserDefaults.standard.bellmanPeripheralUuid = peripheral?.identifier.uuidString
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
            self.notify()
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

        isConnected = false
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        AppLog.info("DidDisconnectPeripheral peripheral: \(peripheral)")

        if let error = error {
            AppLog.error("DidDisconnectPeripheral error: \(error.localizedDescription)")
        }

        isConnected = false
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        AppLog.info("DidConnect peripheral: \(peripheral)")

        isConnected = true
        peripheral.discoverServices([commandServiceUuid, deviceServiceUuid])
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

                if characteristic.uuid == commandCharacteristicUuid {
                    AppLog.info("Characteristic: commandCharacteristicUuid")
                    commandCharacteristic = characteristic
                    
                    peripheral.setNotifyValue(true, for: characteristic)
                }

                if characteristic.uuid == writeCharacteristicUuid {
                    AppLog.info("Characteristic: writeCharacteristicUuid")
                    writeCharacteristic = characteristic
                }
                
                if characteristic.uuid == firmwareCharacteristicUuid {
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
    
    /*private func parseInfo(_ value: [UInt8]) {
        var bytes = subBytes(value, 11, value.count - 11)
        
        String conver2HexStr2 = conver2HexStr(bytes2BigEnd(subBytes(bytes, 0, 3)));
        
        guard value.count >= 7 else {
            return
        }
        
        let sender = bytesToHex(subBytes(value, 4, 3))
        AppLog.info("Sender: \(sender)")

        guard value.count >= 10 else {
            return
        }
        
        let receiver = bytesToHex(subBytes(value, 7, 3))
        AppLog.info("Receiver: \(receiver)")
    }*/
    
    private func bytes2BigEnd(_ bArr: [UInt8]) -> [UInt8] {
        return bArr.reversed();
    }
    
    private func bytesToHex(_ bArr: [UInt8]) -> String {
        var hex = ""
        
        for b in bArr {
            let hexPart = String(format:"%02X", b & 255)
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
            bArr2[i3 - i] = bArr[i3];
        }
        
        return bArr2;
    }

    // MARK: Private

    private var manager: CBCentralManager!
    private let managerQueue = DispatchQueue(label: "libre-direct.bellman-connection.queue")

    private var commandServiceUuid = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    private var deviceServiceUuid = CBUUID(string: "0000180a-0000-1000-8000-00805f9b34fb")
    
    private let firmwareCharacteristicUuid = CBUUID(string: "00002a26-0000-1000-8000-00805f9b34fb")
    private var firmwareCharacteristic: CBCharacteristic?
    
    private let writeCharacteristicUuid = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    private var writeCharacteristic: CBCharacteristic?

    private let commandCharacteristicUuid = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    private var commandCharacteristic: CBCharacteristic?

    private var peripheralName: String {
        "phone transceiver"
    }

    private func connect() {
        AppLog.info("Connect")

        guard manager.state == .poweredOn else {
            AppLog.error("Guard: manager.state \(manager.state.rawValue) is not .poweredOn")
            return
        }

        if let connectedPeripheral = manager.retrieveConnectedPeripherals(withServices: [commandServiceUuid]).first {
            AppLog.info("Connect from retrievePeripherals: \(connectedPeripheral)")

            connect(connectedPeripheral)
        } else {
            managerQueue.asyncAfter(deadline: .now() + .seconds(5)) {
                self.connect()
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
    }

    private func notify() {
        AppLog.info("Notify")

        setShouldNotify(shouldNotify: false)

        if let peripheral = peripheral, let writeCharacteristic = writeCharacteristic {
            peripheral.writeValue(Data([152, 6, 0, 36, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 2, 129, 0, 1, 1]), for: writeCharacteristic, type: .withoutResponse)
        }
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
        case bellmanPeripheralUuid = "libre-direct.bellman.peripheral-uuid"
    }

    var bellmanPeripheralUuid: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.bellmanPeripheralUuid.rawValue)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.setValue(newValue, forKey: Keys.bellmanPeripheralUuid.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.bellmanPeripheralUuid.rawValue)
            }
        }
    }
}
