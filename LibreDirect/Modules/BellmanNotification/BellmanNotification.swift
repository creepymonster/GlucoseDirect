//
//  BellmanNotification.swift
//  LibreDirect
//

import Combine
import Foundation
import CoreBluetooth

func bellmanNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return bellmanNotificationMiddelware(service: {
        BellmanNotificationService()
    }())
}

private func bellmanNotificationMiddelware(service: BellmanNotificationService) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

private class BellmanNotificationService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var serviceUuid: CBUUID = CBUUID(string: "60a60000-cbb8-44a1-83ef-c68a75b6e87d")
    
    lazy var manager: CBCentralManager = {
        CBCentralManager(delegate: self, queue: managerQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }()
    
    let managerQueue = DispatchQueue(label: "libre-direct.bellman-connection.queue")
    
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
