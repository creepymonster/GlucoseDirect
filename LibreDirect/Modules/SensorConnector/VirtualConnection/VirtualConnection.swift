//
//  VirtualConnection.swift
//  LibreDirect
//

import Foundation

// MARK: - VirtualLibreConnection

final class VirtualLibreConnection: SensorConnection {
    // MARK: Internal

    func pairSensor(updatesHandler: @escaping SensorConnectionHandler) {
        self.updatesHandler = updatesHandler

        let sensor = Sensor(
            uuid: Data(hexString: "e9ad9b6c79bd93aa")!,
            patchInfo: Data(hexString: "448cd1")!,
            factoryCalibration: FactoryCalibration(i1: 1, i2: 2, i3: 4, i4: 8, i5: 16, i6: 32),
            customCalibration: [],
            family: .unknown,
            type: .virtual,
            region: .european,
            serial: "OBIR2PO",
            state: .starting,
            age: initAge,
            lifetime: 24 * 60,
            warmupTime: warmupTime
        )

        sendUpdate(sensor: sensor)
    }

    func connectSensor(sensor: Sensor, updatesHandler: @escaping SensorConnectionHandler) {
        self.updatesHandler = updatesHandler

        let fireDate = Date().rounded(on: 1, .minute).addingTimeInterval(60)
        let timer = Timer(fire: fireDate, interval: glucoseInterval, repeats: true) { _ in
            Log.info("fires at \(Date())")

            self.sendNextGlucose()
        }

        RunLoop.main.add(timer, forMode: .common)

        sendUpdate(connectionState: .connected)
    }

    func disconnectSensor() {
        timer?.invalidate()
        timer = nil

        sendUpdate(connectionState: .disconnected)
        updatesHandler = nil
    }

    // MARK: Private
    
    var updatesHandler: SensorConnectionHandler? = nil

    private var initAge = 0
    private var warmupTime = 5
    private var age = 0
    private let glucoseInterval = TimeInterval(60)
    private var sensor: Sensor?
    private var timer: Timer?
    private var direction: VirtualLibreDirection = .up
    private var nextGlucose = 100
    private var nextRotation = 112
    private var lastGlucose = 100

    private func sendNextGlucose() {
        Log.info("direction: \(direction)")

        let currentGlucose = nextGlucose
        Log.info("currentGlucose: \(currentGlucose)")

        age = age + 1

        sendUpdate(age: age, state: age > warmupTime ? .ready : .starting)

        if age > warmupTime {
            sendUpdate(nextReading: SensorReading(id: UUID(), timestamp: Date(), glucoseValue: Double(currentGlucose)))
        }

        let nextAddition = direction == .up ? 1 : -1

        nextGlucose = currentGlucose + (nextAddition * Int.random(in: 0 ..< 12))
        lastGlucose = currentGlucose

        Log.info("nextGlucose: \(nextGlucose)")

        if direction == .up, currentGlucose > nextRotation {
            direction = .down
            nextRotation = Int.random(in: 50 ..< 80)

            Log.info("nextRotation: \(nextRotation)")
        } else if direction == .down, currentGlucose < nextRotation {
            direction = .up
            nextRotation = Int.random(in: 160 ..< 240)

            Log.info("nextRotation: \(nextRotation)")
        }
    }
}

// MARK: - VirtualLibreDirection

private enum VirtualLibreDirection: String {
    case up = "Up"
    case down = "Down"
}
