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
        AppLog.info("DidFailToConnect peripheral: \(peripheral), didFailToConnect")

        if let error = error {
            AppLog.error(error.localizedDescription)
        }

        isConnected = false
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        AppLog.info("DidDisconnectPeripheral peripheral: \(peripheral), didDisconnectPeripheral")

        if let error = error {
            AppLog.error(error.localizedDescription)
        }

        isConnected = false
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        AppLog.info("DidConnect peripheral: \(peripheral)")

        isConnected = true
        peripheral.discoverServices([serviceUuid])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        AppLog.info("DidDiscoverServices peripheral: \(peripheral)")

        if let services = peripheral.services {
            for service in services {
                AppLog.info("Service Uuid: \(service.uuid.description)")
                AppLog.info("Service: \(service)")

                if service.uuid == serviceUuid {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        AppLog.info("DidDiscoverCharacteristicsFor peripheral: \(peripheral)")

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                AppLog.info("Characteristic Uuid: \(characteristic.uuid.description)")
                AppLog.info("Characteristic: \(characteristic)")

                if characteristic.uuid == commandCharacteristicUuid {
                    AppLog.info("Characteristic: commandCharacteristicUuid")
                    commandCharacteristic = characteristic
                }

                if characteristic.uuid == writeCharacteristicUuid {
                    AppLog.info("Characteristic: writeCharacteristicUuid")
                    writeCharacteristic = characteristic

                    // try to send notification
                    peripheral.writeValue(Data([152, 6, 0, 36, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 2, 129, 0, 1, 1]), for: characteristic, type: .withoutResponse)
                }
            }
        }
    }

    // MARK: Private

    private var manager: CBCentralManager!
    private let managerQueue = DispatchQueue(label: "libre-direct.bellman-connection.queue")

    private var serviceUuid = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")

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

        if let connectedPeripheral = manager.retrieveConnectedPeripherals(withServices: [serviceUuid]).first {
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
