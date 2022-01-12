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

    var serviceUuid = CBUUID(string: "60a60000-cbb8-44a1-83ef-c68a75b6e87d")
    var manager: CBCentralManager!

    let managerQueue = DispatchQueue(label: "libre-direct.bellman-connection.queue")

    var peripheral: CBPeripheral? {
        didSet {
            oldValue?.delegate = nil
            peripheral?.delegate = self

            UserDefaults.standard.bellmanPeripheralUuid = peripheral?.identifier.uuidString
        }
    }

    /*func find() {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("find")

        if let connectedPeripheral = manager.retrieveConnectedPeripherals(withServices: [serviceUuid]).first(where: { $0.name?.lowercased().starts(with: peripheralName) ?? false }) {
            AppLog.info("Connect from retrievePeripherals")
            connect(connectedPeripheral)

        } else if let peripheralUuidString = UserDefaults.standard.sensorPeripheralUuid,
                  let peripheralUuid = UUID(uuidString: peripheralUuidString),
                  let retrievedPeripheral = manager.retrievePeripherals(withIdentifiers: [peripheralUuid]).first {
            AppLog.info("Connect from retrievePeripherals")
            connect(retrievedPeripheral)

        }
    }
    
    func connect(_ peripheral: CBPeripheral) {
        dispatchPrecondition(condition: .onQueue(managerQueue))
        AppLog.info("Connect: \(peripheral)")

        if self.peripheral != peripheral {
            self.peripheral = peripheral
        }

        manager.connect(peripheral, options: nil)
    }*/

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        dispatchPrecondition(condition: .onQueue(managerQueue))

        switch manager.state {
        case .poweredOff:
            AppLog.info("poweredOff")

        case .poweredOn:
            AppLog.info("poweredOn")

        default:
            break
        }
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
